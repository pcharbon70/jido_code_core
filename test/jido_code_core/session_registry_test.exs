defmodule JidoCodeCore.SessionRegistryTest do
  use ExUnit.Case, async: false

  alias JidoCodeCore.{Session, SessionRegistry}

  setup do
    # Clean up any existing table before each test
    if SessionRegistry.table_exists?() do
      :ets.delete(JidoCodeCore.SessionRegistry)
    end

    on_exit(fn ->
      # Clean up after test
      if SessionRegistry.table_exists?() do
        :ets.delete(JidoCodeCore.SessionRegistry)
      end
    end)

    :ok
  end

  # Helper to create a valid session for testing
  defp create_test_session(opts \\ []) do
    now = DateTime.utc_now()
    id = Keyword.get(opts, :id, Session.generate_id())
    name = Keyword.get(opts, :name, "test-project")
    project_path = Keyword.get(opts, :project_path, "/tmp/test-project-#{:rand.uniform(100_000)}")

    %Session{
      id: id,
      name: name,
      project_path: project_path,
      config: %{
        provider: "anthropic",
        model: "claude-3-5-sonnet-20241022",
        temperature: 0.7,
        max_tokens: 4096
      },
      created_at: now,
      updated_at: now
    }
  end

  describe "table_exists?/0" do
    test "returns false when table does not exist" do
      refute SessionRegistry.table_exists?()
    end

    test "returns true when table exists" do
      SessionRegistry.create_table()
      assert SessionRegistry.table_exists?()
    end
  end

  describe "create_table/0" do
    test "creates ETS table successfully" do
      refute SessionRegistry.table_exists?()
      assert :ok = SessionRegistry.create_table()
      assert SessionRegistry.table_exists?()
    end

    test "is idempotent - can be called multiple times" do
      assert :ok = SessionRegistry.create_table()
      assert :ok = SessionRegistry.create_table()
      assert SessionRegistry.table_exists?()
    end

    test "creates table with correct name" do
      SessionRegistry.create_table()
      assert :ets.whereis(JidoCodeCore.SessionRegistry) != :undefined
    end

    test "creates table as :set type" do
      SessionRegistry.create_table()
      info = :ets.info(JidoCodeCore.SessionRegistry)
      assert Keyword.get(info, :type) == :set
    end
  end

  describe "max_sessions/0" do
    test "returns default of 10" do
      assert SessionRegistry.max_sessions() == 10
    end

    test "returns configured value when set" do
      original = Application.get_env(:jido_code_core, :max_sessions)

      try do
        Application.put_env(:jido_code_core, :max_sessions, 25)
        assert SessionRegistry.max_sessions() == 25
      after
        if original do
          Application.put_env(:jido_code_core, :max_sessions, original)
        else
          Application.delete_env(:jido_code_core, :max_sessions)
        end
      end
    end
  end

  describe "count/0" do
    test "returns 0 when table is empty" do
      SessionRegistry.create_table()
      assert SessionRegistry.count() == 0
    end

    test "returns 0 when table does not exist" do
      assert SessionRegistry.count() == 0
    end

    test "returns correct count after registrations" do
      SessionRegistry.create_table()
      {:ok, _} = SessionRegistry.register(create_test_session())
      assert SessionRegistry.count() == 1
      {:ok, _} = SessionRegistry.register(create_test_session())
      assert SessionRegistry.count() == 2
    end
  end

  describe "register/1" do
    setup do
      SessionRegistry.create_table()
      :ok
    end

    test "registers a valid session successfully" do
      session = create_test_session()
      assert {:ok, registered} = SessionRegistry.register(session)
      assert registered.id == session.id
      assert registered.name == session.name
    end

    test "increments count after successful registration" do
      session = create_test_session()
      assert SessionRegistry.count() == 0
      {:ok, _} = SessionRegistry.register(session)
      assert SessionRegistry.count() == 1
    end

    test "session can be found in ETS table after registration" do
      session = create_test_session()
      {:ok, _} = SessionRegistry.register(session)
      [{id, stored}] = :ets.lookup(JidoCodeCore.SessionRegistry, session.id)
      assert id == session.id
      assert stored == session
    end

    test "returns error for duplicate session ID" do
      session1 = create_test_session(id: "same-id", project_path: "/tmp/project1")
      session2 = create_test_session(id: "same-id", project_path: "/tmp/project2")
      {:ok, _} = SessionRegistry.register(session1)
      assert {:error, :session_exists} = SessionRegistry.register(session2)
    end

    test "returns error for duplicate project_path" do
      session1 = create_test_session(project_path: "/tmp/same-project")
      session2 = create_test_session(project_path: "/tmp/same-project")
      {:ok, _} = SessionRegistry.register(session1)
      assert {:error, :project_already_open} = SessionRegistry.register(session2)
    end

    test "returns error when session limit (10) is reached" do
      # Register 10 sessions
      for i <- 1..10 do
        session = create_test_session(project_path: "/tmp/project-#{i}")
        {:ok, _} = SessionRegistry.register(session)
      end

      assert SessionRegistry.count() == 10

      # 11th session should fail
      session11 = create_test_session(project_path: "/tmp/project-11")
      assert {:error, {:session_limit_reached, 10, 10}} = SessionRegistry.register(session11)
    end
  end

  describe "lookup/1" do
    setup do
      SessionRegistry.create_table()
      :ok
    end

    test "finds registered session by ID" do
      session = create_test_session()
      {:ok, _} = SessionRegistry.register(session)

      assert {:ok, found} = SessionRegistry.lookup(session.id)
      assert found.id == session.id
      assert found.project_path == session.project_path
    end

    test "returns error for unknown ID" do
      assert {:error, :not_found} = SessionRegistry.lookup("nonexistent-id")
    end
  end

  describe "lookup_by_path/1" do
    setup do
      SessionRegistry.create_table()
      :ok
    end

    test "finds session by project path" do
      session = create_test_session(project_path: "/tmp/my-project")
      {:ok, _} = SessionRegistry.register(session)

      assert {:ok, found} = SessionRegistry.lookup_by_path("/tmp/my-project")
      assert found.project_path == "/tmp/my-project"
    end

    test "returns error for unknown path" do
      assert {:error, :not_found} = SessionRegistry.lookup_by_path("/tmp/nonexistent")
    end
  end

  describe "list_all/0" do
    test "returns empty list when table does not exist" do
      assert SessionRegistry.list_all() == []
    end

    test "returns empty list when table is empty" do
      SessionRegistry.create_table()
      assert SessionRegistry.list_all() == []
    end

    test "returns all registered sessions" do
      SessionRegistry.create_table()
      session1 = create_test_session(project_path: "/tmp/project1")
      session2 = create_test_session(project_path: "/tmp/project2")
      {:ok, _} = SessionRegistry.register(session1)
      {:ok, _} = SessionRegistry.register(session2)

      sessions = SessionRegistry.list_all()
      assert length(sessions) == 2
    end
  end

  describe "unregister/1" do
    test "removes session from registry" do
      SessionRegistry.create_table()
      session = create_test_session()
      {:ok, session} = SessionRegistry.register(session)

      assert SessionRegistry.count() == 1
      result = SessionRegistry.unregister(session.id)

      assert result == :ok
      assert SessionRegistry.count() == 0
      assert SessionRegistry.lookup(session.id) == {:error, :not_found}
    end

    test "returns :ok even if session did not exist" do
      SessionRegistry.create_table()
      result = SessionRegistry.unregister("non-existent-id")
      assert result == :ok
    end
  end

  describe "clear/0" do
    test "removes all sessions from registry" do
      SessionRegistry.create_table()
      session1 = create_test_session(project_path: "/tmp/project1")
      session2 = create_test_session(project_path: "/tmp/project2")
      {:ok, _} = SessionRegistry.register(session1)
      {:ok, _} = SessionRegistry.register(session2)

      assert SessionRegistry.count() == 2
      result = SessionRegistry.clear()

      assert result == :ok
      assert SessionRegistry.count() == 0
    end

    test "returns :ok when table is empty" do
      SessionRegistry.create_table()
      result = SessionRegistry.clear()
      assert result == :ok
    end
  end

  describe "update/1" do
    test "updates existing session successfully" do
      SessionRegistry.create_table()
      session = create_test_session()
      {:ok, session} = SessionRegistry.register(session)

      updated_session = %{session | name: "new-name", updated_at: DateTime.utc_now()}
      result = SessionRegistry.update(updated_session)

      assert {:ok, ^updated_session} = result
    end

    test "returns error for non-existent session" do
      SessionRegistry.create_table()
      session = create_test_session()
      result = SessionRegistry.update(session)
      assert result == {:error, :not_found}
    end
  end
end
