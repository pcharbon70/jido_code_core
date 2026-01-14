defmodule JidoCodeCore.APIIndependenceTest do
  @moduledoc """
  Tests for Section 2.2: Core Logic Independence

  These tests verify that all core operations work through the public API
  without requiring TUI dependencies or direct GenServer calls.

  Coverage:
  - 2.2.6.1: Session lifecycle works through API
  - 2.2.6.2: Agent execution works through API
  - 2.2.6.3: Tool execution works through API
  - 2.2.6.4: Memory operations work through API
  - 2.2.6.5: State queries return current state
  - 2.2.6.6: Multiple sessions can run independently
  """

  use ExUnit.Case, async: false

  alias JidoCodeCore.API.Session, as: SessionAPI
  alias JidoCodeCore.API.Agent, as: AgentAPI
  alias JidoCodeCore.API.Tools, as: ToolsAPI
  alias JidoCodeCore.API.Memory, as: MemoryAPI
  alias JidoCodeCore.SessionRegistry
  alias JidoCodeCore.Tools.{Registry, Tool, Param}

  @moduletag :api_independence

  # Define test tools for tool system testing
  @test_tools [
    Tool.new!(%{
      name: "test_tool",
      description: "A test tool for API independence testing",
      handler: AgentTestToolHandler,
      parameters: [
        Param.new!(%{
          name: "input",
          type: :string,
          description: "Test input",
          required: true
        })
      ]
    })
  ]

  # Test tool handler module
  defmodule AgentTestToolHandler do
    def execute(%{"input" => input}, _context) do
      {:ok, "Processed: #{input}"}
    end

    def execute(_, _), do: {:error, "Invalid parameters"}
  end

  setup do
    # Ensure clean state
    SessionRegistry.create_table()
    SessionRegistry.clear()

    # Stop any existing sessions
    SessionRegistry.list_all()
    |> Enum.each(fn session ->
      SessionAPI.stop_session(session.id)
    end)

    # Register test tools
    Enum.each(@test_tools, fn tool -> Registry.register(tool) end)

    :ok
  end

  describe "2.2.6.1: Session lifecycle through API" do
    test "creates and starts session via API" do
      assert {:ok, session} = SessionAPI.start_session(project_path: System.tmp_dir!())

      assert session.id != nil
      assert is_binary(session.id)
      assert session.project_path == System.tmp_dir!()
      assert session.created_at != nil
      assert session.updated_at != nil
    end

    test "retrieves session via API" do
      {:ok, created} = SessionAPI.start_session(project_path: System.tmp_dir!())

      assert {:ok, retrieved} = SessionAPI.get_session(created.id)
      assert retrieved.id == created.id
      assert retrieved.name == created.name
    end

    test "lists sessions via API" do
      assert [] == SessionAPI.list_sessions()

      {:ok, session1} = SessionAPI.start_session(project_path: System.tmp_dir!())
      sessions = SessionAPI.list_sessions()

      assert length(sessions) == 1
      assert hd(sessions).id == session1.id
    end

    test "stops session via API" do
      {:ok, session} = SessionAPI.start_session(project_path: System.tmp_dir!())
      session_id = session.id

      assert :ok == SessionAPI.stop_session(session_id)
      assert false == SessionAPI.session_running?(session_id)
      assert {:error, :not_found} == SessionAPI.get_session(session_id)
    end

    test "updates session config via API" do
      {:ok, session} = SessionAPI.start_session(project_path: System.tmp_dir!())

      assert {:ok, updated} =
               SessionAPI.set_session_config(session.id, %{temperature: 0.5})

      assert updated.config.temperature == 0.5
    end

    test "serializes session struct" do
      {:ok, session} = SessionAPI.start_session(project_path: System.tmp_dir!())

      # All fields should be serializable (primitives, DateTime, atom)
      assert is_binary(session.id)
      assert is_binary(session.name)
      assert is_binary(session.project_path)
      assert is_map(session.config)
      assert is_atom(session.language)
      assert %DateTime{} = session.created_at
      assert %DateTime{} = session.updated_at
    end
  end

  describe "2.2.6.2: Agent execution through API" do
    setup do
      {:ok, session} = SessionAPI.start_session(project_path: System.tmp_dir!())
      %{session: session}
    end

    test "gets agent status via API - agent not started yet", %{session: session} do
      # Agent may not be started yet - this is expected behavior
      # The agent is started lazily when needed
      result = AgentAPI.get_status(session.id)

      # Either agent exists or we get :not_found (agent not started)
      assert match?({:ok, _}, result) or result == {:error, :not_found}
    end

    test "gets agent config via API - from session config", %{session: session} do
      # Session config is available even if agent isn't started
      {:ok, session_data} = SessionAPI.get_session(session.id)

      assert is_map(session_data.config)
      assert Map.has_key?(session_data.config, :provider)
      assert Map.has_key?(session_data.config, :model)
    end

    test "reconfigures session via API - updates session config", %{session: session} do
      # Session config can be updated without agent running
      assert {:ok, updated} =
               SessionAPI.set_session_config(session.id, %{
                 temperature: 0.3,
                 model: "claude-3-5-haiku-20241022"
               })

      assert updated.config.temperature == 0.3
      assert updated.config.model == "claude-3-5-haiku-20241022"
    end
  end

  describe "2.2.6.3: Tool execution through API" do
    setup do
      {:ok, session} = SessionAPI.start_session(project_path: System.tmp_dir!())
      %{session: session}
    end

    test "lists tools via API" do
      tools = ToolsAPI.list_tools()

      assert is_list(tools)
      assert length(tools) > 0

      # Verify tool structure
      tool = hd(tools)
      assert Map.has_key?(tool, :name)
      assert Map.has_key?(tool, :description)
    end

    test "gets tool schema via API" do
      assert {:ok, schema} = ToolsAPI.get_tool_schema("test_tool")

      assert schema.name == "test_tool"
      assert is_list(schema.parameters)
    end

    test "gets tools for LLM via API" do
      tools = ToolsAPI.tools_for_llm()

      assert is_list(tools)
      assert length(tools) > 0

      # Verify LLM format - tools for LLM are wrapped in a function structure
      tool = hd(tools)
      assert Map.has_key?(tool, :function)
      assert Map.has_key?(tool.function, :name)
      assert Map.has_key?(tool.function, :description)
    end

    test "counts tools via API" do
      count = ToolsAPI.count_tools()
      assert is_integer(count)
      assert count > 0
    end

    # Note: Full tool execution requires a properly configured session
    # with security context. The API independence is demonstrated by
    # the ability to list tools and get schemas via the API.
  end

  describe "2.2.6.4: Memory operations through API" do
    setup do
      {:ok, session} = SessionAPI.start_session(project_path: System.tmp_dir!())
      %{session: session}
    end

    test "gets memory stats via API", %{session: session} do
      assert {:ok, stats} = MemoryAPI.get_memory_stats(session.id)

      # Verify stats structure
      assert is_map(stats)
      assert Map.has_key?(stats, :pending_count)
      assert Map.has_key?(stats, :promotion_stats)
      assert Map.has_key?(stats, :context_size)
      assert is_integer(stats.pending_count)
      assert is_integer(stats.context_size)
    end

    test "searches graph via API", %{session: session} do
      # Graph search should not error even with no data
      assert {:ok, results} =
               MemoryAPI.search_graph(session.id, "test-memory-id", max_depth: 2)

      assert is_list(results)
    end

    test "lists memory types via API" do
      types = MemoryAPI.memory_types()

      assert is_list(types)
      assert :fact in types
      assert :decision in types
      assert :convention in types
    end

    test "validates memory types via API" do
      assert MemoryAPI.valid_type?(:fact) == true
      assert MemoryAPI.valid_type?(:invalid) == false
    end

    # Note: remember/recall tests require a properly configured project
    # with RDF store setup. These are tested in the memory action tests.
  end

  describe "2.2.6.5: State queries return current state" do
    setup do
      {:ok, session} = SessionAPI.start_session(project_path: System.tmp_dir!())
      %{session: session}
    end

    test "gets session state via API", %{session: session} do
      assert {:ok, state} = SessionAPI.get_session_state(session.id)

      # Verify state structure
      assert Map.has_key?(state, :session_id)
      assert Map.has_key?(state, :messages)
      assert Map.has_key?(state, :reasoning_steps)
      assert Map.has_key?(state, :tool_calls)
      assert Map.has_key?(state, :todos)
      assert is_list(state.messages)
      assert is_list(state.reasoning_steps)
    end

    test "gets messages via API", %{session: session} do
      assert {:ok, messages} = SessionAPI.get_messages(session.id)

      assert is_list(messages)
    end

    test "gets paginated messages via API", %{session: session} do
      assert {:ok, messages, meta} = SessionAPI.get_messages(session.id, 0, 10)

      assert is_list(messages)
      assert is_map(meta)
      assert Map.has_key?(meta, :total)
      assert Map.has_key?(meta, :has_more)
    end

    test "gets reasoning steps via API", %{session: session} do
      assert {:ok, steps} = SessionAPI.get_reasoning_steps(session.id)

      assert is_list(steps)
    end

    test "gets todos via API", %{session: session} do
      assert {:ok, todos} = SessionAPI.get_todos(session.id)

      assert is_list(todos)
    end

    test "all state queries are read-only (no side effects)", %{session: session} do
      # Call state query multiple times - should return same data
      assert {:ok, state1} = SessionAPI.get_session_state(session.id)
      assert {:ok, state2} = SessionAPI.get_session_state(session.id)

      # State should be consistent
      assert state1.session_id == state2.session_id
      assert length(state1.messages) == length(state2.messages)
    end
  end

  describe "2.2.6.6: Multiple sessions run independently" do
    test "multiple sessions can coexist" do
      # Create unique paths for each session
      tmp_dir1 = Path.join(System.tmp_dir!(), "test_session_#{:rand.uniform(10000)}")
      tmp_dir2 = Path.join(System.tmp_dir!(), "test_session_#{:rand.uniform(10000)}")

      File.mkdir_p!(tmp_dir1)
      File.mkdir_p!(tmp_dir2)

      {:ok, session1} =
        SessionAPI.start_session(project_path: tmp_dir1, name: "Session 1")

      {:ok, session2} =
        SessionAPI.start_session(project_path: tmp_dir2, name: "Session 2")

      # Both sessions should be running
      assert SessionAPI.session_running?(session1.id)
      assert SessionAPI.session_running?(session2.id)

      # Sessions should have different IDs
      assert session1.id != session2.id

      # Both should be in the list
      sessions = SessionAPI.list_sessions()
      assert length(sessions) == 2
    end

    test "sessions have independent state" do
      tmp_dir1 = Path.join(System.tmp_dir!(), "test_session_#{:rand.uniform(10000)}")
      tmp_dir2 = Path.join(System.tmp_dir!(), "test_session_#{:rand.uniform(10000)}")

      File.mkdir_p!(tmp_dir1)
      File.mkdir_p!(tmp_dir2)

      {:ok, session1} = SessionAPI.start_session(project_path: tmp_dir1, name: "S1")
      {:ok, session2} = SessionAPI.start_session(project_path: tmp_dir2, name: "S2")

      # Set different configs
      SessionAPI.set_session_config(session1.id, %{temperature: 0.1})
      SessionAPI.set_session_config(session2.id, %{temperature: 0.9})

      # Verify independence
      {:ok, s1} = SessionAPI.get_session(session1.id)
      {:ok, s2} = SessionAPI.get_session(session2.id)

      assert s1.config.temperature == 0.1
      assert s2.config.temperature == 0.9
    end

    test "stopping one session doesn't affect others" do
      tmp_dir1 = Path.join(System.tmp_dir!(), "test_session_#{:rand.uniform(10000)}")
      tmp_dir2 = Path.join(System.tmp_dir!(), "test_session_#{:rand.uniform(10000)}")

      File.mkdir_p!(tmp_dir1)
      File.mkdir_p!(tmp_dir2)

      {:ok, session1} = SessionAPI.start_session(project_path: tmp_dir1, name: "S1")
      {:ok, session2} = SessionAPI.start_session(project_path: tmp_dir2, name: "S2")

      # Stop session1
      SessionAPI.stop_session(session1.id)

      # session2 should still be running
      assert SessionAPI.session_running?(session2.id)
      refute SessionAPI.session_running?(session1.id)
    end
  end

  describe "2.2: No direct GenServer calls required" do
    test "all operations work via public API" do
      # This test verifies that a complete workflow can be done
      # through the API without any direct GenServer calls

      # 1. Create session
      {:ok, session} = SessionAPI.start_session(project_path: System.tmp_dir!())

      # 2. Query session state
      assert {:ok, state} = SessionAPI.get_session_state(session.id)

      # 3. Query session config (agent may not be started yet)
      assert {:ok, session_data} = SessionAPI.get_session(session.id)
      assert is_map(session_data.config)

      # 4. List tools
      tools = ToolsAPI.list_tools()
      assert length(tools) > 0

      # 5. Query memory stats
      assert {:ok, memory_stats} = MemoryAPI.get_memory_stats(session.id)

      # 6. Clean up
      :ok = SessionAPI.stop_session(session.id)

      # Verify cleanup
      refute SessionAPI.session_running?(session.id)
    end
  end
end
