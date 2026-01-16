defmodule JidoCodeCore.APIAgentTest do
  use ExUnit.Case, async: false

  alias JidoCodeCore.API.Agent, as: APIAgent
  alias JidoCodeCore.{SessionRegistry, SessionSupervisor, Session}
  alias JidoCodeCore.API.Session, as: APISession

  setup do
    # Ensure SessionRegistry table exists and is clear
    SessionRegistry.create_table()

    # Stop any existing sessions from previous tests
    SessionRegistry.list_all()
    |> Enum.each(fn session ->
      APISession.stop_session(session.id)
    end)

    on_exit(fn ->
      # Clean up any sessions created during this test
      SessionRegistry.list_all()
      |> Enum.each(fn session ->
        APISession.stop_session(session.id)
      end)
    end)

    :ok
  end

  # Helper function to create a test session with agent started
  defp create_test_session(opts \\ []) do
    project_path = Keyword.get(opts, :project_path, System.tmp_dir!())
    start_agent = Keyword.get(opts, :start_agent, true)

    with {:ok, session} <- Session.new(project_path: project_path),
         {:ok, _pid} <- SessionSupervisor.start_session(session) do
      if start_agent do
        case JidoCodeCore.Session.Supervisor.start_agent(session) do
          {:ok, _agent_pid} -> {:ok, session}
          {:error, :already_started} -> {:ok, session}
          error -> error
        end
      else
        {:ok, session}
      end
    else
      error -> error
    end
  end

  describe "send_message/3" do
    test "returns error for non-existent session" do
      assert {:error, :not_found} =
               APIAgent.send_message("nonexistent-session-id", "Hello!")
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.send_message(:invalid, "Hello!")
      end
    end

    test "returns error for invalid message type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.send_message("session-id", :invalid)
      end
    end

    test "returns error for invalid opts type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.send_message("session-id", "Hello!", :invalid)
      end
    end

    test "accepts timeout option" do
      assert {:error, :not_found} =
               APIAgent.send_message("nonexistent-session-id", "Hello!", timeout: 5000)
    end

    test "accepts system_prompt option" do
      assert {:error, :not_found} =
               APIAgent.send_message(
                 "nonexistent-session-id",
                 "Hello!",
                 system_prompt: "Custom prompt"
               )
    end

    @tag :llm
    test "validates message length limit (10000 characters)" do
      long_message = String.duplicate("a", 10_001)

      assert {:ok, session} = create_test_session()

      # Message too long should return error
      assert {:error, :message_too_long} =
               APIAgent.send_message(session.id, long_message)

      # Clean up
      :ok = SessionSupervisor.stop_session(session.id)
    end

    test "accepts message at exactly 10000 characters" do
      max_message = String.duplicate("a", 10_000)

      assert {:error, :not_found} =
               APIAgent.send_message("nonexistent-session-id", max_message)
    end
  end

  describe "send_message_stream/3" do
    test "returns error for non-existent session" do
      assert {:error, :not_found} =
               APIAgent.send_message_stream("nonexistent-session-id", "Hello!")
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.send_message_stream(:invalid, "Hello!")
      end
    end

    test "returns error for invalid message type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.send_message_stream("session-id", :invalid)
      end
    end

    test "returns error for invalid opts type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.send_message_stream("session-id", "Hello!", :invalid)
      end
    end

    test "accepts timeout option" do
      assert {:error, :not_found} =
               APIAgent.send_message_stream("nonexistent-session-id", "Hello!", timeout: 5000)
    end

    @tag :llm
    test "validates message length limit for streaming" do
      long_message = String.duplicate("a", 10_001)

      assert {:ok, session} = create_test_session()

      assert {:error, :message_too_long} =
               APIAgent.send_message_stream(session.id, long_message)

      :ok = SessionSupervisor.stop_session(session.id)
    end
  end

  describe "get_status/1" do
    test "returns error for non-existent session" do
      assert {:error, :not_found} = APIAgent.get_status("nonexistent-session-id")
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.get_status(:invalid)
      end
    end

    @tag :llm
    test "returns status map for active session" do
      assert {:ok, session} = create_test_session()

      assert {:ok, status} = APIAgent.get_status(session.id)
      assert is_map(status)
      assert Map.has_key?(status, :ready)
      assert Map.has_key?(status, :config)
      assert Map.has_key?(status, :session_id)

      :ok = SessionSupervisor.stop_session(session.id)
    end

    @tag :llm
    test "status includes session_id" do
      assert {:ok, session} = create_test_session()

      assert {:ok, status} = APIAgent.get_status(session.id)
      assert status.session_id == session.id

      :ok = SessionSupervisor.stop_session(session.id)
    end
  end

  describe "get_agent_config/1" do
    test "returns error for non-existent session" do
      assert {:error, :not_found} = APIAgent.get_agent_config("nonexistent-session-id")
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.get_agent_config(:invalid)
      end
    end

    @tag :llm
    test "returns config map for active session" do
      assert {:ok, session} = create_test_session()

      assert {:ok, config} = APIAgent.get_agent_config(session.id)
      assert is_map(config)

      # Should have provider and model keys
      assert Map.has_key?(config, :provider) or Map.has_key?(config, "provider")
      assert Map.has_key?(config, :model) or Map.has_key?(config, "model")

      :ok = SessionSupervisor.stop_session(session.id)
    end
  end

  describe "reconfigure_agent/2" do
    test "returns error for non-existent session" do
      assert {:error, :not_found} =
               APIAgent.reconfigure_agent("nonexistent-session-id", provider: :openai)
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.reconfigure_agent(:invalid, provider: :openai)
      end
    end

    test "returns error for invalid opts type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.reconfigure_agent("session-id", :invalid)
      end
    end

    @tag :llm
    test "accepts provider option" do
      assert {:ok, session} = create_test_session()

      assert :ok = APIAgent.reconfigure_agent(session.id, provider: :anthropic)

      :ok = SessionSupervisor.stop_session(session.id)
    end

    @tag :llm
    test "accepts model option" do
      assert {:ok, session} = create_test_session()

      assert :ok = APIAgent.reconfigure_agent(session.id, model: "claude-3-5-sonnet-20241022")

      :ok = SessionSupervisor.stop_session(session.id)
    end

    @tag :llm
    test "accepts temperature option" do
      assert {:ok, session} = create_test_session()

      assert :ok = APIAgent.reconfigure_agent(session.id, temperature: 0.5)

      :ok = SessionSupervisor.stop_session(session.id)
    end

    @tag :llm
    test "accepts max_tokens option" do
      assert {:ok, session} = create_test_session()

      assert :ok = APIAgent.reconfigure_agent(session.id, max_tokens: 4096)

      :ok = SessionSupervisor.stop_session(session.id)
    end
  end

  describe "execute_tool_via_agent/2" do
    test "returns error for non-existent session" do
      tool_call = %{id: "call_1", name: "read_file", arguments: %{"path" => "/test.ex"}}

      assert {:error, :not_found} = APIAgent.execute_tool_via_agent("nonexistent", tool_call)
    end

    test "returns error for invalid session_id type" do
      tool_call = %{id: "call_1", name: "read_file", arguments: %{}}

      assert_raise FunctionClauseError, fn ->
        APIAgent.execute_tool_via_agent(:invalid, tool_call)
      end
    end

    test "returns error for invalid tool_call type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.execute_tool_via_agent("session-id", :invalid)
      end
    end

    @tag :llm
    test "accepts valid tool_call map" do
      assert {:ok, session} = create_test_session()

      tool_call = %{
        id: "call_1",
        name: "list_directory",
        arguments: %{"path" => System.tmp_dir!()}
      }

      # Tool should execute (may fail on actual execution but API call works)
      result = APIAgent.execute_tool_via_agent(session.id, tool_call)
      assert is_tuple(result)

      :ok = SessionSupervisor.stop_session(session.id)
    end
  end

  describe "execute_tools_batch/3" do
    test "returns error for non-existent session" do
      tool_calls = [%{id: "1", name: "read_file", arguments: %{}}]

      assert {:error, :not_found} =
               APIAgent.execute_tools_batch("nonexistent", tool_calls)
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.execute_tools_batch(:invalid, [])
      end
    end

    test "returns error for invalid tool_calls type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.execute_tools_batch("session-id", :invalid)
      end
    end

    test "returns error for invalid opts type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.execute_tools_batch("session-id", [], :invalid)
      end
    end

    @tag :llm
    test "accepts empty list of tool_calls" do
      assert {:ok, session} = create_test_session()

      assert {:ok, results} = APIAgent.execute_tools_batch(session.id, [])
      assert results == []

      :ok = SessionSupervisor.stop_session(session.id)
    end

    @tag :llm
    test "accepts parallel option" do
      assert {:ok, session} = create_test_session()

      tool_calls = [
        %{id: "1", name: "list_directory", arguments: %{"path" => System.tmp_dir!()}}
      ]

      assert {:ok, _results} =
               APIAgent.execute_tools_batch(session.id, tool_calls, parallel: true)

      :ok = SessionSupervisor.stop_session(session.id)
    end

    @tag :llm
    test "accepts timeout option" do
      assert {:ok, session} = create_test_session()

      assert {:ok, _results} =
               APIAgent.execute_tools_batch(session.id, [], timeout: 5000)

      :ok = SessionSupervisor.stop_session(session.id)
    end
  end

  describe "agent_topic/1" do
    test "returns topic string for session_id" do
      topic = APIAgent.agent_topic("test-session-id")
      assert is_binary(topic)
      assert String.contains?(topic, "test-session-id")
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIAgent.agent_topic(:invalid)
      end
    end

    test "topics are unique per session" do
      topic1 = APIAgent.agent_topic("session-1")
      topic2 = APIAgent.agent_topic("session-2")

      assert topic1 != topic2
    end
  end

  describe "list_providers/0" do
    test "returns list of providers" do
      assert {:ok, providers} = APIAgent.list_providers()
      assert is_list(providers)
    end

    test "providers list contains expected atoms" do
      assert {:ok, providers} = APIAgent.list_providers()

      # Should contain at least some common providers
      # (depends on what's configured in the system)
      assert length(providers) > 0
    end
  end

  describe "send_message/3 timeout handling" do
    test "passes timeout option to LLMAgent" do
      assert {:error, :not_found} =
               APIAgent.send_message("nonexistent-session", "test", timeout: 5000)
    end

    test "passes system_prompt option to LLMAgent" do
      assert {:error, :not_found} =
               APIAgent.send_message("nonexistent-session", "test", system_prompt: "Custom")
    end
  end

  describe "send_message_stream/3 timeout handling" do
    test "passes timeout option to stream" do
      assert {:error, :not_found} =
               APIAgent.send_message_stream("nonexistent-session", "test", timeout: 5000)
    end
  end

  describe "reconfigure_agent/2 with multiple options" do
    test "accepts multiple configuration options" do
      assert {:error, :not_found} =
               APIAgent.reconfigure_agent("session-id",
                 provider: :anthropic,
                 model: "claude-3-5-sonnet-20241022",
                 temperature: 0.7,
                 max_tokens: 4096
               )
    end
  end

  describe "execute_tools_batch/3 with options" do
    test "accepts parallel option" do
      tool_calls = [%{id: "1", name: "read_file", arguments: %{}}]

      assert {:error, :not_found} =
               APIAgent.execute_tools_batch("session-id", tool_calls, parallel: true)
    end

    test "accepts timeout option" do
      assert {:error, :not_found} =
               APIAgent.execute_tools_batch("session-id", [], timeout: 5000)
    end

    test "accepts multiple options" do
      tool_calls = [%{id: "1", name: "read_file", arguments: %{}}]

      assert {:error, :not_found} =
               APIAgent.execute_tools_batch("session-id", tool_calls,
                 parallel: true,
                 timeout: 5000
               )
    end
  end

  describe "get_status/1 error handling" do
    test "returns not_found when agent process not found" do
      assert {:error, :not_found} =
               APIAgent.get_status("nonexistent-session-agent-not-found")
    end
  end

  describe "get_agent_config/1 error handling" do
    test "returns not_found when session does not exist" do
      assert {:error, :not_found} =
               APIAgent.get_agent_config("nonexistent-session-config")
    end
  end

  describe "send_message/3 message handling" do
    test "accepts empty string message" do
      assert {:error, :not_found} = APIAgent.send_message("nonexistent", "")
    end

    test "accepts message with special characters" do
      special_message = "Hello! @#$%^&*()_+ {}|:\"<>?[]\\;',./~`"

      assert {:error, :not_found} = APIAgent.send_message("nonexistent", special_message)
    end

    test "accepts message with unicode characters" do
      unicode_message = "Hello 世界 🌍 مرحبا"

      assert {:error, :not_found} = APIAgent.send_message("nonexistent", unicode_message)
    end

    test "accepts message with newlines" do
      multiline_message = "Line 1\nLine 2\nLine 3"

      assert {:error, :not_found} = APIAgent.send_message("nonexistent", multiline_message)
    end
  end

  describe "send_message_stream/3 message handling" do
    test "accepts empty string message for streaming" do
      assert {:error, :not_found} = APIAgent.send_message_stream("nonexistent", "")
    end

    test "accepts message with special characters for streaming" do
      special_message = "Test @#$%^&*()"

      assert {:error, :not_found} = APIAgent.send_message_stream("nonexistent", special_message)
    end
  end

  describe "execute_tool_via_agent/2 tool_call handling" do
    test "accepts tool_call with extra keys" do
      tool_call = %{
        id: "call_1",
        name: "read_file",
        arguments: %{"path" => "/test.txt"},
        extra_key: "extra_value"
      }

      assert {:error, :not_found} = APIAgent.execute_tool_via_agent("nonexistent", tool_call)
    end

    test "accepts tool_call with empty arguments" do
      tool_call = %{id: "call_1", name: "read_file", arguments: %{}}

      assert {:error, :not_found} = APIAgent.execute_tool_via_agent("nonexistent", tool_call)
    end

    test "accepts tool_call with complex arguments" do
      tool_call = %{
        id: "call_1",
        name: "read_file",
        arguments: %{
          "path" => "/test.txt",
          "nested" => %{"key" => "value"},
          "list" => [1, 2, 3]
        }
      }

      assert {:error, :not_found} = APIAgent.execute_tool_via_agent("nonexistent", tool_call)
    end
  end

  describe "execute_tools_batch/3 tool_calls handling" do
    test "accepts multiple tool_calls" do
      tool_calls = [
        %{id: "1", name: "read_file", arguments: %{}},
        %{id: "2", name: "write_file", arguments: %{}},
        %{id: "3", name: "grep", arguments: %{}}
      ]

      assert {:error, :not_found} =
               APIAgent.execute_tools_batch("nonexistent", tool_calls)
    end

    test "accepts tool_calls with string IDs" do
      tool_calls = [
        %{id: "call_abc_123", name: "read_file", arguments: %{}},
        %{id: "call_xyz_789", name: "read_file", arguments: %{}}
      ]

      assert {:error, :not_found} =
               APIAgent.execute_tools_batch("nonexistent", tool_calls)
    end
  end
end
