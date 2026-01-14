defmodule JidoCodeCore.IntegrationTest do
  @moduledoc """
  Integration tests for JidoCodeCore end-to-end flows.

  These tests verify that different components work together correctly:
  - Supervision tree startup and process registration
  - Session lifecycle (start/stop sessions)
  - Tool registration and execution
  - PubSub message delivery
  """

  use ExUnit.Case, async: false

  alias JidoCodeCore.{Session, SessionSupervisor, SessionRegistry}
  alias JidoCodeCore.Tools.{Tool, Param, Executor}
  alias JidoCodeCore.Tools.Registry, as: ToolsRegistry
  alias JidoCodeCore.Test.SessionSupervisorStub

  # Mock handler for testing
  defmodule MockToolHandler do
    def execute(%{"msg" => msg}, _context), do: {:ok, "Echo: #{msg}"}
    def execute(_params, _context), do: {:ok, "executed"}
  end

  setup do
    # Ensure SessionRegistry table exists and is clear
    SessionRegistry.create_table()
    SessionRegistry.clear()

    # Clean up any sessions from previous tests
    SessionRegistry.list_all()
    |> Enum.each(fn session ->
      SessionSupervisor.stop_session(session.id)
    end)

    # Clear tool registry
    ToolsRegistry.clear()

    on_exit(fn ->
      # Clean up any sessions created during this test
      SessionRegistry.list_all()
      |> Enum.each(fn session ->
        SessionSupervisor.stop_session(session.id)
      end)

      SessionRegistry.clear()
      ToolsRegistry.clear()
    end)

    :ok
  end

  describe "supervision tree startup" do
    test "application supervision tree starts SessionSupervisor" do
      # Verify SessionSupervisor is running (Application may not have a named process)
      assert Process.whereis(JidoCodeCore.SessionSupervisor) != nil
      assert Process.alive?(Process.whereis(JidoCodeCore.SessionSupervisor))
    end

    test "SessionProcessRegistry accepts process registrations" do
      # Use Elixir.Registry explicitly to avoid conflict with Tools.Registry alias
      test_name = :"integration_test_#{:rand.uniform(100_000)}"
      registry = JidoCodeCore.SessionProcessRegistry

      {:ok, _} = Elixir.Registry.register(registry, {:test, test_name}, %{type: :test})

      # Verify lookup works
      [{pid, value}] = Elixir.Registry.lookup(registry, {:test, test_name})
      assert pid == self()
      assert value == %{type: :test}

      # Clean up
      Elixir.Registry.unregister(registry, {:test, test_name})
    end
  end

  describe "session lifecycle" do
    test "creates and starts a session successfully" do
      {:ok, session} =
        SessionSupervisor.create_session(
          project_path: System.tmp_dir!(),
          supervisor_module: SessionSupervisorStub
        )

      assert %Session{} = session
      assert SessionSupervisor.session_running?(session.id)
    end

    test "session is registered in SessionRegistry" do
      {:ok, session} =
        SessionSupervisor.create_session(
          project_path: System.tmp_dir!(),
          supervisor_module: SessionSupervisorStub
        )

      assert {:ok, registered} = SessionRegistry.lookup(session.id)
      assert registered.id == session.id
    end

    test "stops session cleanly" do
      {:ok, session} =
        SessionSupervisor.create_session(
          project_path: System.tmp_dir!(),
          supervisor_module: SessionSupervisorStub
        )

      session_id = session.id
      assert SessionSupervisor.session_running?(session_id)

      :ok = SessionSupervisor.stop_session(session_id)

      # Give process time to terminate
      :timer.sleep(100)
      refute SessionSupervisor.session_running?(session_id)
      assert {:error, :not_found} = SessionRegistry.lookup(session_id)
    end

    test "can create and stop multiple sessions" do
      # Use unique project paths for each session
      path1 = Path.join(System.tmp_dir!(), "project_test_#{:rand.uniform(100_000)}")
      path2 = Path.join(System.tmp_dir!(), "project_test_#{:rand.uniform(100_000)}")

      File.mkdir_p!(path1)
      File.mkdir_p!(path2)

      {:ok, s1} =
        SessionSupervisor.create_session(
          project_path: path1,
          supervisor_module: SessionSupervisorStub
        )

      {:ok, s2} =
        SessionSupervisor.create_session(
          project_path: path2,
          supervisor_module: SessionSupervisorStub
        )

      assert SessionSupervisor.session_running?(s1.id)
      assert SessionSupervisor.session_running?(s2.id)

      :ok = SessionSupervisor.stop_session(s1.id)
      :timer.sleep(100)

      assert SessionSupervisor.session_running?(s2.id)
      refute SessionSupervisor.session_running?(s1.id)
    end
  end

  describe "tool registration and execution" do
    test "registers and executes a tool" do
      # Register a test tool
      tool =
        Tool.new!(%{
          name: "test_tool",
          description: "Test tool for integration",
          handler: MockToolHandler,
          parameters: [
            Param.new!(%{name: "msg", type: :string, description: "Message", required: true})
          ]
        })

      :ok = ToolsRegistry.register(tool)

      # Verify it's registered
      assert {:ok, ^tool} = ToolsRegistry.get("test_tool")
      assert ToolsRegistry.registered?("test_tool")

      # Execute the tool
      tool_call = %{id: "call_1", name: "test_tool", arguments: %{"msg" => "hello"}}
      assert {:ok, result} = Executor.execute(tool_call)

      assert result.status == :ok
      assert result.content == "Echo: hello"
      assert result.tool_name == "test_tool"
    end

    test "executes batch of tools" do
      # Register test tools
      tool1 =
        Tool.new!(%{
          name: "echo_tool",
          description: "Echo tool",
          handler: MockToolHandler,
          parameters: []
        })

      tool2 =
        Tool.new!(%{
          name: "another_tool",
          description: "Another tool",
          handler: MockToolHandler,
          parameters: []
        })

      :ok = ToolsRegistry.register(tool1)
      :ok = ToolsRegistry.register(tool2)

      # Execute batch
      tool_calls = [
        %{id: "call_1", name: "echo_tool", arguments: %{}},
        %{id: "call_2", name: "another_tool", arguments: %{}}
      ]

      assert {:ok, results} = Executor.execute_batch(tool_calls)
      assert length(results) == 2
      assert Enum.all?(results, fn r -> r.status == :ok end)
    end
  end

  describe "end-to-end: session with tool execution" do
    test "creates session and executes tools in context" do
      # Create a session
      {:ok, session} =
        SessionSupervisor.create_session(
          project_path: System.tmp_dir!(),
          supervisor_module: SessionSupervisorStub
        )

      # Register a tool
      tool =
        Tool.new!(%{
          name: "context_tool",
          description: "Context-aware tool",
          handler: MockToolHandler,
          parameters: []
        })

      :ok = ToolsRegistry.register(tool)

      # Execute tool with session context
      tool_call = %{id: "call_ctx", name: "context_tool", arguments: %{}}
      context = %{session_id: session.id, project_root: System.tmp_dir!()}

      assert {:ok, result} = Executor.execute(tool_call, context: context)
      assert result.status == :ok

      # Clean up
      :ok = SessionSupervisor.stop_session(session.id)
    end
  end

  describe "tool parsing and execution flow" do
    test "parses LLM response and executes tools" do
      # Register a tool
      tool =
        Tool.new!(%{
          name: "parse_test_tool",
          description: "Tool for parsing test",
          handler: MockToolHandler,
          parameters: [
            Param.new!(%{name: "msg", type: :string, description: "Message", required: true})
          ]
        })

      :ok = ToolsRegistry.register(tool)

      # Simulate LLM response
      llm_response = %{
        "tool_calls" => [
          %{
            "id" => "call_parse",
            "type" => "function",
            "function" => %{
              "name" => "parse_test_tool",
              "arguments" => ~s({"msg": "test message"})
            }
          }
        ]
      }

      # Parse tool calls
      assert {:ok, [tool_call]} = Executor.parse_tool_calls(llm_response)
      assert tool_call.name == "parse_test_tool"
      assert tool_call.arguments == %{"msg" => "test message"}

      # Execute tool
      assert {:ok, result} = Executor.execute(tool_call)
      assert result.status == :ok
      assert result.content == "Echo: test message"
    end
  end

  describe "registry operations across multiple sessions" do
    test "handles concurrent tool operations" do
      # Register multiple tools
      for i <- 1..5 do
        tool =
          Tool.new!(%{
            name: "tool_#{i}",
            description: "Tool #{i}",
            handler: MockToolHandler,
            parameters: []
          })

        :ok = ToolsRegistry.register(tool)
      end

      # Verify all are registered
      assert ToolsRegistry.count() == 5

      tools = ToolsRegistry.list()
      assert length(tools) == 5

      # Execute all tools
      tool_calls =
        for i <- 1..5 do
          %{id: "call_#{i}", name: "tool_#{i}", arguments: %{}}
        end

      assert {:ok, results} = Executor.execute_batch(tool_calls, parallel: true)
      assert length(results) == 5
    end
  end
end
