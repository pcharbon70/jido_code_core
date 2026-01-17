defmodule JidoCodeCore.APISessionTest do
  use ExUnit.Case, async: false

  alias JidoCodeCore.API.Session, as: APISession
  alias JidoCodeCore.{SessionRegistry}

  setup do
    # Ensure SessionRegistry table exists and is clear
    SessionRegistry.create_table()

    # Stop any existing sessions from previous tests
    SessionRegistry.list_all()
    |> Enum.each(fn session ->
      APISession.stop_session(session.id)
    end)

    # Clear the registry
    SessionRegistry.clear()

    :ok
  end

  describe "start_session/1" do
    test "starts a session with valid project path" do
      assert {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert session.id != nil
      assert session.project_path == System.tmp_dir!()
      assert is_binary(session.name)
      assert session.created_at != nil
    end

    test "starts a session with custom name" do
      assert {:ok, session} =
               APISession.start_session(
                 project_path: System.tmp_dir!(),
                 name: "Test Session"
               )

      assert session.name == "Test Session"
    end

    test "starts a session with custom config" do
      config = %{
        provider: :anthropic,
        model: "claude-3-5-haiku-20241022",
        temperature: 0.5
      }

      assert {:ok, session} =
               APISession.start_session(project_path: System.tmp_dir!(), config: config)

      assert session.config.provider == :anthropic
      assert session.config.model == "claude-3-5-haiku-20241022"
      assert session.config.temperature == 0.5
    end

    test "returns error for non-existent path" do
      assert {:error, :path_not_found} =
               APISession.start_session(project_path: "/nonexistent/path/that/does/not/exist")
    end

    test "returns error for file path (not directory)" do
      # Create a temporary file
      tmp_file = Path.join(System.tmp_dir!(), "test_file_#{:rand.uniform(100_000)}")
      File.write!(tmp_file, "test")

      assert {:error, :path_not_directory} =
               APISession.start_session(project_path: tmp_file)

      File.rm!(tmp_file)
    end
  end

  describe "stop_session/1" do
    test "stops a running session" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())
      session_id = session.id

      assert :ok = APISession.stop_session(session_id)

      # Session should no longer be running
      refute APISession.session_running?(session_id)

      # Session should no longer be in registry
      assert {:error, :not_found} = SessionRegistry.lookup(session_id)
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = APISession.stop_session("non-existent-session-id")
    end
  end

  describe "list_sessions/0" do
    test "returns empty list when no sessions exist" do
      assert [] == APISession.list_sessions()
    end

    test "returns all active sessions" do
      {:ok, session1} = APISession.start_session(project_path: System.tmp_dir!())

      # Create a second temp directory for another session
      tmp_dir2 = Path.join(System.tmp_dir!(), "second_test_#{:rand.uniform(100_000)}")
      File.mkdir_p!(tmp_dir2)

      {:ok, session2} = APISession.start_session(project_path: tmp_dir2)

      sessions = APISession.list_sessions()

      assert length(sessions) == 2
      session_ids = Enum.map(sessions, & &1.id)
      assert session1.id in session_ids
      assert session2.id in session_ids

      # Cleanup
      File.rm_rf!(tmp_dir2)
    end

    test "returns sessions sorted by created_at" do
      {:ok, session1} = APISession.start_session(project_path: System.tmp_dir!())
      # Ensure different timestamps
      Process.sleep(10)

      tmp_dir2 = Path.join(System.tmp_dir!(), "second_test_#{:rand.uniform(100_000)}")
      File.mkdir_p!(tmp_dir2)
      {:ok, session2} = APISession.start_session(project_path: tmp_dir2)

      sessions = APISession.list_sessions()

      assert length(sessions) == 2
      # First created should be first
      assert List.first(sessions).id == session1.id
      assert List.last(sessions).id == session2.id

      # Cleanup
      File.rm_rf!(tmp_dir2)
    end
  end

  describe "get_session/1" do
    test "returns session when it exists" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, found} = APISession.get_session(session.id)
      assert found.id == session.id
      assert found.project_path == session.project_path
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = APISession.get_session("non-existent-id")
    end
  end

  describe "get_session_by_path/1" do
    test "returns session when path matches" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, found} = APISession.get_session_by_path(System.tmp_dir!())
      assert found.id == session.id
    end

    test "returns error for non-existent path" do
      assert {:error, :not_found} = APISession.get_session_by_path("/nonexistent/path")
    end
  end

  describe "session_running?/1" do
    test "returns true for running session" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert APISession.session_running?(session.id)
    end

    test "returns false for non-existent session" do
      refute APISession.session_running?("non-existent-id")
    end

    test "returns false after stopping session" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())
      APISession.stop_session(session.id)

      refute APISession.session_running?(session.id)
    end
  end

  describe "set_session_config/2" do
    test "updates session config" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, updated} =
               APISession.set_session_config(session.id, %{
                 temperature: 0.3,
                 model: "claude-3-5-sonnet-20241022"
               })

      assert updated.config.temperature == 0.3
      assert updated.config.model == "claude-3-5-sonnet-20241022"
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} =
               APISession.set_session_config("non-existent-id", %{temperature: 0.5})
    end
  end

  describe "set_session_language/2" do
    test "sets language with atom" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, updated} = APISession.set_session_language(session.id, :python)

      assert updated.language == :python
    end

    test "sets language with string" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, updated} = APISession.set_session_language(session.id, "javascript")

      assert updated.language == :javascript
    end

    test "sets language with alias" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, updated} = APISession.set_session_language(session.id, "js")

      assert updated.language == :javascript
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = APISession.set_session_language("non-existent-id", :python)
    end
  end

  describe "rename_session/2" do
    test "renames a session" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())
      original_id = session.id

      assert {:ok, renamed} = APISession.rename_session(session.id, "New Name")
      assert renamed.id == original_id
      assert renamed.name == "New Name"

      # Verify the session is still registered with new name
      assert {:ok, found} = APISession.get_session(original_id)
      assert found.name == "New Name"
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = APISession.rename_session("non-existent-id", "New Name")
    end
  end

  describe "get_session_state/1" do
    test "returns state for active session" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, state} = APISession.get_session_state(session.id)

      assert is_map(state)
      assert Map.has_key?(state, :messages)
      assert Map.has_key?(state, :todos)
      assert Map.has_key?(state, :reasoning_steps)
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = APISession.get_session_state("non-existent-id")
    end
  end

  describe "get_messages/1" do
    test "returns empty list for new session" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, messages} = APISession.get_messages(session.id)
      assert messages == []
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = APISession.get_messages("non-existent-id")
    end
  end

  describe "get_messages/3 (paginated)" do
    test "returns empty list with pagination metadata for new session" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, messages, meta} = APISession.get_messages(session.id, 0, 10)

      assert messages == []
      assert meta.total == 0
      assert meta.offset == 0
      assert meta.limit == 10
      assert meta.returned == 0
      assert meta.has_more == false
    end

    test "respects limit parameter" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, _messages, meta} = APISession.get_messages(session.id, 0, 5)

      assert meta.limit == 5
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = APISession.get_messages("non-existent-id", 0, 10)
    end
  end

  describe "get_reasoning_steps/1" do
    test "returns empty list for new session" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, steps} = APISession.get_reasoning_steps(session.id)
      assert steps == []
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = APISession.get_reasoning_steps("non-existent-id")
    end
  end

  describe "get_todos/1" do
    test "returns empty list for new session" do
      {:ok, session} = APISession.start_session(project_path: System.tmp_dir!())

      assert {:ok, todos} = APISession.get_todos(session.id)
      assert todos == []
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = APISession.get_todos("non-existent-id")
    end
  end
end
