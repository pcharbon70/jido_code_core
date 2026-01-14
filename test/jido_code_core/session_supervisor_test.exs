defmodule JidoCodeCore.SessionSupervisorTest do
  use ExUnit.Case, async: false

  alias JidoCodeCore.{Session, SessionRegistry, SessionSupervisor}
  alias JidoCodeCore.Test.SessionSupervisorStub

  setup do
    # Ensure SessionRegistry table exists and is clear
    SessionRegistry.create_table()
    SessionRegistry.clear()

    # Clean up any sessions from previous tests
    SessionRegistry.list_all()
    |> Enum.each(fn session ->
      SessionSupervisor.stop_session(session.id)
    end)

    on_exit(fn ->
      # Clean up any sessions created during this test
      SessionRegistry.list_all()
      |> Enum.each(fn session ->
        SessionSupervisor.stop_session(session.id)
      end)

      SessionRegistry.clear()
    end)

    :ok
  end

  describe "start_link/1" do
    test "supervisor is running from application" do
      pid = Process.whereis(SessionSupervisor)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "returns error when already started" do
      assert {:error, {:already_started, _}} = SessionSupervisor.start_link([])
    end
  end

  describe "init/1" do
    test "initializes with :one_for_one strategy" do
      assert {:ok, spec} = SessionSupervisor.init([])
      assert is_map(spec)
      assert spec.strategy == :one_for_one
    end
  end

  describe "start_session/1" do
    test "starts a session and returns pid" do
      {:ok, session} = Session.new(project_path: System.tmp_dir!())

      assert {:ok, pid} =
               SessionSupervisor.start_session(session, supervisor_module: SessionSupervisorStub)

      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "registers session in SessionRegistry" do
      {:ok, session} = Session.new(project_path: System.tmp_dir!())

      {:ok, _pid} =
        SessionSupervisor.start_session(session, supervisor_module: SessionSupervisorStub)

      assert {:ok, registered} = SessionRegistry.lookup(session.id)
      assert registered.id == session.id
    end

    test "registers session process in SessionProcessRegistry" do
      {:ok, session} = Session.new(project_path: System.tmp_dir!())

      {:ok, pid} =
        SessionSupervisor.start_session(session, supervisor_module: SessionSupervisorStub)

      assert [{^pid, _}] =
               Registry.lookup(JidoCodeCore.SessionProcessRegistry, {:session, session.id})
    end

    test "fails with :session_exists for duplicate ID" do
      {:ok, session} = Session.new(project_path: System.tmp_dir!())

      {:ok, _} =
        SessionSupervisor.start_session(session, supervisor_module: SessionSupervisorStub)

      assert {:error, :session_exists} =
               SessionSupervisor.start_session(session, supervisor_module: SessionSupervisorStub)
    end

    test "fails with :project_already_open for duplicate path" do
      {:ok, session1} = Session.new(project_path: System.tmp_dir!())
      {:ok, session2} = Session.new(project_path: System.tmp_dir!())

      {:ok, _} =
        SessionSupervisor.start_session(session1, supervisor_module: SessionSupervisorStub)

      assert {:error, :project_already_open} =
               SessionSupervisor.start_session(session2, supervisor_module: SessionSupervisorStub)
    end
  end

  describe "stop_session/1" do
    test "stops a running session" do
      {:ok, session} = Session.new(project_path: System.tmp_dir!())

      {:ok, pid} =
        SessionSupervisor.start_session(session, supervisor_module: SessionSupervisorStub)

      assert Process.alive?(pid)
      assert :ok = SessionSupervisor.stop_session(session.id)

      # Give the process time to terminate
      :timer.sleep(100)
      refute Process.alive?(pid)
    end

    test "unregisters session from SessionRegistry" do
      {:ok, session} = Session.new(project_path: System.tmp_dir!())

      {:ok, _} =
        SessionSupervisor.start_session(session, supervisor_module: SessionSupervisorStub)

      assert {:ok, _} = SessionRegistry.lookup(session.id)

      :ok = SessionSupervisor.stop_session(session.id)
      assert {:error, :not_found} = SessionRegistry.lookup(session.id)
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = SessionSupervisor.stop_session("non-existent-id")
    end
  end

  describe "find_session_pid/1" do
    test "finds registered session pid" do
      {:ok, session} = Session.new(project_path: System.tmp_dir!())

      {:ok, expected_pid} =
        SessionSupervisor.start_session(session, supervisor_module: SessionSupervisorStub)

      assert {:ok, pid} = SessionSupervisor.find_session_pid(session.id)
      assert pid == expected_pid
    end

    test "returns error for unknown session" do
      assert {:error, :not_found} = SessionSupervisor.find_session_pid("unknown-session-id")
    end
  end

  describe "list_session_pids/0" do
    test "returns a list of pids" do
      pids = SessionSupervisor.list_session_pids()
      assert is_list(pids)
    end

    test "includes pids for running sessions" do
      {:ok, session} = Session.new(project_path: System.tmp_dir!())

      {:ok, pid} =
        SessionSupervisor.start_session(session, supervisor_module: SessionSupervisorStub)

      pids = SessionSupervisor.list_session_pids()
      assert pid in pids
    end
  end

  describe "session_running?/1" do
    test "returns true for running session" do
      {:ok, session} = Session.new(project_path: System.tmp_dir!())

      {:ok, _} =
        SessionSupervisor.start_session(session, supervisor_module: SessionSupervisorStub)

      assert SessionSupervisor.session_running?(session.id) == true
    end

    test "returns false for unknown session" do
      assert SessionSupervisor.session_running?("unknown-session-id") == false
    end
  end

  describe "create_session/1" do
    test "creates and starts a session" do
      assert {:ok, session} =
               SessionSupervisor.create_session(
                 project_path: System.tmp_dir!(),
                 supervisor_module: SessionSupervisorStub
               )

      assert %Session{} = session
      assert session.project_path == System.tmp_dir!()
    end

    test "registers session in SessionRegistry" do
      {:ok, session} =
        SessionSupervisor.create_session(
          project_path: System.tmp_dir!(),
          supervisor_module: SessionSupervisorStub
        )

      assert {:ok, registered} = SessionRegistry.lookup(session.id)
      assert registered.id == session.id
    end

    test "session is running after creation" do
      {:ok, session} =
        SessionSupervisor.create_session(
          project_path: System.tmp_dir!(),
          supervisor_module: SessionSupervisorStub
        )

      assert SessionSupervisor.session_running?(session.id)
    end

    test "fails for non-existent path" do
      assert {:error, :path_not_found} =
               SessionSupervisor.create_session(
                 project_path: "/nonexistent/path/that/does/not/exist",
                 supervisor_module: SessionSupervisorStub
               )
    end
  end
end
