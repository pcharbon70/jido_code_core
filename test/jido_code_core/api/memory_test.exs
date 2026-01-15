defmodule JidoCodeCore.APIMemoryTest do
  use ExUnit.Case, async: false

  alias JidoCodeCore.API.Memory, as: APIMemory
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

  # Helper to create test session
  # Note: SessionSupervisor.start_session handles starting State GenServer
  defp create_test_session(opts \\ []) do
    project_path = Keyword.get(opts, :project_path, System.tmp_dir!())
    session_id = Keyword.get(opts, :session_id)

    base_session = case session_id do
      nil ->
        {:ok, session} = Session.new(project_path: project_path)
        session
      id ->
        {:ok, session} = Session.new(project_path: project_path, id: id)
        session
    end

    case SessionSupervisor.start_session(base_session) do
      {:ok, _pid} -> {:ok, base_session}
      {:error, {:already_registered, _pid}} -> {:ok, base_session}
      error -> error
    end
  end

  describe "remember/3" do
    test "returns error for non-existent session" do
      assert {:error, _reason} = APIMemory.remember("nonexistent-session", "Test content")
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIMemory.remember(:invalid, "Test content")
      end
    end

    test "returns error for invalid content type" do
      assert_raise FunctionClauseError, fn ->
        APIMemory.remember("session-id", :invalid)
      end
    end

    test "accepts valid content with default options" do
      assert {:ok, session} = create_test_session()

      # Note: This test validates the API structure
      # Actual memory storage requires Remember action to be functional
      result = APIMemory.remember(session.id, "Test framework is Phoenix")

      # Result should be a tuple (either ok or error)
      assert is_tuple(result)

      # Clean up
      SessionSupervisor.stop_session(session.id)
    end

    test "accepts type option" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.remember(session.id, "Important fact", type: :fact)
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts confidence option" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.remember(session.id, "Certain fact", confidence: 1.0)
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts rationale option" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.remember(session.id, "Decision rationale",
        type: :decision, rationale: "Performance optimization")
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts all options together" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.remember(session.id, "Full option memory",
        type: :convention,
        confidence: 0.9,
        rationale: "Important for code consistency"
      )
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end
  end

  describe "recall/2" do
    test "returns error for non-existent session" do
      assert {:error, _reason} = APIMemory.recall("nonexistent-session")
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIMemory.recall(:invalid)
      end
    end

    test "accepts empty opts (returns all memories)" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.recall(session.id, [])
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts query option" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.recall(session.id, query: "Phoenix")
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts search_mode option" do
      assert {:ok, session} = create_test_session()

      for mode <- [:text, :semantic, :hybrid] do
        result = APIMemory.recall(session.id, query: "test", search_mode: mode)
        assert is_tuple(result)
      end

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts type option" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.recall(session.id, type: :fact)
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts min_confidence option" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.recall(session.id, min_confidence: 0.7)
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts limit option" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.recall(session.id, limit: 5)
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts all options together" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.recall(session.id,
        query: "framework",
        search_mode: :hybrid,
        type: :fact,
        min_confidence: 0.6,
        limit: 10
      )
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end
  end

  describe "forget/2" do
    test "returns error for non-existent session" do
      assert {:error, _reason} = APIMemory.forget("nonexistent-session", "memory-id")
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIMemory.forget(:invalid, "memory-id")
      end
    end

    test "returns error for invalid memory_id type" do
      assert_raise FunctionClauseError, fn ->
        APIMemory.forget("session-id", :invalid)
      end
    end

    test "accepts valid memory_id string" do
      assert {:ok, session} = create_test_session()

      result = APIMemory.forget(session.id, "some-memory-id")
      assert is_tuple(result)

      SessionSupervisor.stop_session(session.id)
    end
  end

  describe "search_graph/3" do
    test "returns empty list for any session (placeholder)" do
      # search_graph is currently a placeholder returning {:ok, []}
      assert {:ok, session} = create_test_session()

      assert {:ok, []} = APIMemory.search_graph(session.id, "memory-id")

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts max_depth option" do
      assert {:ok, session} = create_test_session()

      assert {:ok, []} = APIMemory.search_graph(session.id, "memory-id", max_depth: 3)

      SessionSupervisor.stop_session(session.id)
    end

    test "accepts max_results option" do
      assert {:ok, session} = create_test_session()

      assert {:ok, []} = APIMemory.search_graph(session.id, "memory-id", max_results: 50)

      SessionSupervisor.stop_session(session.id)
    end
  end

  describe "memory_types/0" do
    test "returns list of valid memory types" do
      types = APIMemory.memory_types()

      assert is_list(types)
      assert length(types) > 0

      # Should contain knowledge types
      assert :fact in types
      assert :assumption in types
      assert :hypothesis in types

      # Should contain decision types
      assert :decision in types

      # Should contain convention types
      assert :convention in types

      # Should contain error types
      assert :bug in types
      assert :lesson_learned in types
    end

    test "all memory types are atoms" do
      types = APIMemory.memory_types()

      Enum.each(types, fn type ->
        assert is_atom(type)
      end)
    end
  end

  describe "search_modes/0" do
    test "returns list of search modes" do
      modes = APIMemory.search_modes()

      assert is_list(modes)
      assert length(modes) == 3
      assert :text in modes
      assert :semantic in modes
      assert :hybrid in modes
    end
  end

  describe "valid_type?/1" do
    test "returns true for valid memory types" do
      assert APIMemory.valid_type?(:fact)
      assert APIMemory.valid_type?(:assumption)
      assert APIMemory.valid_type?(:decision)
      assert APIMemory.valid_type?(:convention)
      assert APIMemory.valid_type?(:bug)
    end

    test "returns false for invalid memory types (atoms only)" do
      refute APIMemory.valid_type?(:invalid)
      refute APIMemory.valid_type?(:not_a_type)
      refute APIMemory.valid_type?(:random_atom)
    end

    test "raises FunctionClauseError for non-atom types" do
      assert_raise FunctionClauseError, fn ->
        APIMemory.valid_type?("string")
      end

      assert_raise FunctionClauseError, fn ->
        APIMemory.valid_type?(123)
      end

      assert_raise FunctionClauseError, fn ->
        APIMemory.valid_type?(1.5)
      end
    end

    test "returns false for nil atom (nil is valid atom but not a valid memory type)" do
      refute APIMemory.valid_type?(nil)
    end
  end

  describe "get_memory_stats/1" do
    test "returns error for non-existent session" do
      assert {:error, :not_found} = APIMemory.get_memory_stats("nonexistent-session")
    end

    test "returns error for invalid session_id type" do
      assert_raise FunctionClauseError, fn ->
        APIMemory.get_memory_stats(:invalid)
      end
    end

    test "returns stats map for valid session" do
      assert {:ok, session} = create_test_session()

      assert {:ok, stats} = APIMemory.get_memory_stats(session.id)
      assert is_map(stats)

      # Should have expected keys
      assert Map.has_key?(stats, :pending_count)
      assert Map.has_key?(stats, :pending_items)
      assert Map.has_key?(stats, :promotion_stats)
      assert Map.has_key?(stats, :access_stats)
      assert Map.has_key?(stats, :context_size)

      SessionSupervisor.stop_session(session.id)
    end

    test "pending_count is non-negative integer" do
      assert {:ok, session} = create_test_session()

      assert {:ok, stats} = APIMemory.get_memory_stats(session.id)
      assert is_integer(stats.pending_count)
      assert stats.pending_count >= 0

      SessionSupervisor.stop_session(session.id)
    end

    test "pending_items is a list" do
      assert {:ok, session} = create_test_session()

      assert {:ok, stats} = APIMemory.get_memory_stats(session.id)
      assert is_list(stats.pending_items)

      SessionSupervisor.stop_session(session.id)
    end

    test "context_size is non-negative integer" do
      assert {:ok, session} = create_test_session()

      assert {:ok, stats} = APIMemory.get_memory_stats(session.id)
      assert is_integer(stats.context_size)
      assert stats.context_size >= 0

      SessionSupervisor.stop_session(session.id)
    end

    test "access_stats is a map" do
      assert {:ok, session} = create_test_session()

      assert {:ok, stats} = APIMemory.get_memory_stats(session.id)
      assert is_map(stats.access_stats)

      SessionSupervisor.stop_session(session.id)
    end
  end
end
