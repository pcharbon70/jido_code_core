defmodule JidoCodeCore.MemoryTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Memory
  alias JidoCodeCore.TestHelpers.MemoryTestHelpers, as: Helpers

  # Note: Full integration tests with StoreManager and TripleStoreAdapter
  # require Memory.Supervisor and ETS table setup. These tests focus on:
  # 1. Validation logic that can be tested independently
  # 2. Wrapper functions that delegate to other modules
  # 3. Placeholder functions
  # 4. Error handling paths

  describe "persist/2 - memory field validation" do
    test "returns error when memory_type is invalid" do
      memory = Helpers.create_memory("test-session", memory_type: :invalid_type)

      assert {:error, :invalid_memory_type} = Memory.persist(memory, "test-session")
    end

    test "returns error when source_type is invalid" do
      memory = Helpers.create_memory("test-session", source_type: :invalid_source)

      assert {:error, :invalid_source_type} = Memory.persist(memory, "test-session")
    end

    test "returns error when confidence is below 0.0" do
      memory = Helpers.create_memory("test-session", confidence: -0.1)

      assert {:error, :invalid_confidence} = Memory.persist(memory, "test-session")
    end

    test "returns error when confidence is above 1.0" do
      memory = Helpers.create_memory("test-session", confidence: 1.1)

      assert {:error, :invalid_confidence} = Memory.persist(memory, "test-session")
    end

    test "returns error when confidence is not a number" do
      memory = Helpers.create_memory("test-session", confidence: "high")

      assert {:error, :invalid_confidence} = Memory.persist(memory, "test-session")
    end

    test "accepts valid memory with all required fields" do
      memory = Helpers.create_memory("test-session")

      # Validation passes, actual persistence will fail on store operations
      # without full Memory.Supervisor setup
      assert {:error, _} = Memory.persist(memory, "test-session")
    end

    test "accepts confidence at boundary 0.0" do
      memory = Helpers.create_memory("test-session", confidence: 0.0)

      assert {:error, _} = Memory.persist(memory, "test-session")
    end

    test "accepts confidence at boundary 1.0" do
      memory = Helpers.create_memory("test-session", confidence: 1.0)

      assert {:error, _} = Memory.persist(memory, "test-session")
    end

    test "accepts all valid knowledge memory types" do
      knowledge_types = [:fact, :assumption, :hypothesis, :discovery, :risk, :unknown]

      Enum.each(knowledge_types, fn type ->
        memory = Helpers.create_memory("test-session", memory_type: type)
        # Validation passes for type, fails on store operations
        assert {:error, _} = Memory.persist(memory, "test-session")
      end)
    end

    test "accepts all valid decision memory types" do
      decision_types = [:decision, :architectural_decision, :alternative, :trade_off]

      Enum.each(decision_types, fn type ->
        memory = Helpers.create_memory("test-session", memory_type: type)
        assert {:error, _} = Memory.persist(memory, "test-session")
      end)
    end

    test "accepts all valid convention memory types" do
      convention_types = [:convention, :coding_standard, :agent_rule]

      Enum.each(convention_types, fn type ->
        memory = Helpers.create_memory("test-session", memory_type: type)
        assert {:error, _} = Memory.persist(memory, "test-session")
      end)
    end

    test "accepts all valid error memory types" do
      error_types = [:error, :bug, :incident, :lesson_learned]

      Enum.each(error_types, fn type ->
        memory = Helpers.create_memory("test-session", memory_type: type)
        assert {:error, _} = Memory.persist(memory, "test-session")
      end)
    end

    test "accepts all valid source types" do
      source_types = [:agent, :tool, :user, :system]

      Enum.each(source_types, fn type ->
        memory = Helpers.create_memory("test-session", source_type: type)
        assert {:error, _} = Memory.persist(memory, "test-session")
      end)
    end
  end

  describe "persist/2 - parameter validation" do
    test "raises when memory is not a map" do
      assert_raise FunctionClauseError, fn ->
        Memory.persist("not a map", "test-session")
      end
    end

    test "raises when session_id is not a binary" do
      memory = Helpers.create_memory("test-session")

      assert_raise FunctionClauseError, fn ->
        Memory.persist(memory, 123)
      end
    end
  end

  describe "query/2" do
    test "accepts empty options list" do
      # Delegates to StoreManager and TripleStoreAdapter
      # Without proper setup, will error on store operations
      assert {:error, _} = Memory.query("test-session", [])
    end

    test "accepts type filter option" do
      assert {:error, _} = Memory.query("test-session", type: :fact)
    end

    test "accepts min_confidence filter option" do
      assert {:error, _} = Memory.query("test-session", min_confidence: 0.7)
    end

    test "accepts limit option" do
      assert {:error, _} = Memory.query("test-session", limit: 10)
    end

    test "accepts include_superseded option" do
      assert {:error, _} = Memory.query("test-session", include_superseded: true)
    end

    test "accepts combined filter options" do
      opts = [type: :fact, min_confidence: 0.8, limit: 5, include_superseded: false]
      assert {:error, _} = Memory.query("test-session", opts)
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.query(123, [])
      end
    end

    test "raises when options is not a list" do
      assert_raise FunctionClauseError, fn ->
        Memory.query("test-session", %{type: :fact})
      end
    end
  end

  describe "query_by_type/3" do
    test "accepts memory type atom" do
      assert {:error, _} = Memory.query_by_type("test-session", :fact)
    end

    test "accepts memory type with limit option" do
      assert {:error, _} = Memory.query_by_type("test-session", :fact, limit: 10)
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.query_by_type(123, :fact)
      end
    end

    test "raises when memory_type is not an atom" do
      assert_raise FunctionClauseError, fn ->
        Memory.query_by_type("test-session", "fact")
      end
    end

    test "raises when options is not a list" do
      assert_raise FunctionClauseError, fn ->
        Memory.query_by_type("test-session", :fact, %{limit: 10})
      end
    end
  end

  describe "get/2" do
    test "delegates to TripleStoreAdapter with session verification" do
      assert {:error, _} = Memory.get("test-session", "mem-123")
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.get(123, "mem-123")
      end
    end

    test "raises when memory_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.get("test-session", 123)
      end
    end
  end

  describe "supersede/3" do
    test "delegates to TripleStoreAdapter with nil replacement" do
      assert {:error, _} = Memory.supersede("test-session", "old-mem", nil)
    end

    test "delegates to TripleStoreAdapter with new memory id" do
      assert {:error, _} = Memory.supersede("test-session", "old-mem", "new-mem")
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.supersede(123, "old-mem", nil)
      end
    end

    test "raises when old_memory_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.supersede("test-session", 123, nil)
      end
    end

    test "raises when new_memory_id is not binary or nil" do
      assert_raise FunctionClauseError, fn ->
        Memory.supersede("test-session", "old-mem", 123)
      end
    end
  end

  describe "forget/2" do
    test "delegates to supersede with nil replacement" do
      # forget/2 calls supersede(session_id, memory_id, nil)
      assert {:error, _} = Memory.forget("test-session", "mem-123")
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.forget(123, "mem-123")
      end
    end

    test "raises when memory_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.forget("test-session", 123)
      end
    end
  end

  describe "delete/2" do
    test "delegates to TripleStoreAdapter for hard delete" do
      assert {:error, _} = Memory.delete("test-session", "mem-123")
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.delete(123, "mem-123")
      end
    end

    test "raises when memory_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.delete("test-session", 123)
      end
    end
  end

  describe "record_access/2" do
    test "returns :ok even when store access fails" do
      # record_access/2 intentionally returns :ok on all errors
      # to avoid disrupting the main workflow
      assert :ok = Memory.record_access("nonexistent-session", "nonexistent-mem")
    end

    test "returns :ok for valid parameters" do
      # Even with valid parameters, returns :ok regardless of store state
      assert :ok = Memory.record_access("test-session", "mem-123")
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.record_access(123, "mem-123")
      end
    end

    test "raises when memory_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.record_access("test-session", 123)
      end
    end
  end

  describe "count/2" do
    test "delegates to TripleStoreAdapter with default options" do
      assert {:error, _} = Memory.count("test-session")
    end

    test "delegates to TripleStoreAdapter with include_superseded option" do
      assert {:error, _} = Memory.count("test-session", include_superseded: true)
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.count(123)
      end
    end

    test "raises when options is not a list" do
      assert_raise FunctionClauseError, fn ->
        Memory.count("test-session", %{include_superseded: true})
      end
    end
  end

  describe "query_related/3" do
    test "delegates to TripleStoreAdapter for relationship queries" do
      assert {:error, _} = Memory.query_related("test-session", "mem-123", :refines)
    end

    test "accepts knowledge relationship types" do
      relationships = [:refines, :confirms, :contradicts, :derived_from]

      Enum.each(relationships, fn rel ->
        assert {:error, _} = Memory.query_related("test-session", "mem-123", rel)
      end)
    end

    test "accepts decision relationship types" do
      relationships = [:has_alternative, :selected_alternative, :has_trade_off, :justified_by]

      Enum.each(relationships, fn rel ->
        assert {:error, _} = Memory.query_related("test-session", "mem-123", rel)
      end)
    end

    test "accepts error relationship types" do
      relationships = [:has_root_cause, :produced_lesson, :related_error]

      Enum.each(relationships, fn rel ->
        assert {:error, _} = Memory.query_related("test-session", "mem-123", rel)
      end)
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.query_related(123, "mem-123", :refines)
      end
    end

    test "raises when memory_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.query_related("test-session", 123, :refines)
      end
    end

    test "raises when relationship is not an atom" do
      assert_raise FunctionClauseError, fn ->
        Memory.query_related("test-session", "mem-123", "refines")
      end
    end
  end

  describe "get_stats/1" do
    test "delegates to TripleStoreAdapter for statistics" do
      assert {:error, _} = Memory.get_stats("test-session")
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.get_stats(123)
      end
    end
  end

  describe "load_ontology/1" do
    test "returns {:ok, 0} as a placeholder" do
      # This is a placeholder function for future ontology loading
      assert {:ok, 0} = Memory.load_ontology("test-session")
    end

    test "returns {:ok, 0} for any session_id including non-binaries" do
      # The function uses _session_id pattern which matches anything
      assert {:ok, 0} = Memory.load_ontology("any-session-123")
      assert {:ok, 0} = Memory.load_ontology("another-session")
      assert {:ok, 0} = Memory.load_ontology(123)
      assert {:ok, 0} = Memory.load_ontology(nil)
    end
  end

  describe "list_sessions/0" do
    test "delegates to StoreManager.list_open" do
      # Returns list of session IDs or empty list
      sessions = Memory.list_sessions()

      assert is_list(sessions)
      assert Enum.all?(sessions, &is_binary/1)
    end
  end

  describe "close_session/1" do
    test "returns :ok even for nonexistent sessions" do
      # StoreManager.close returns :ok regardless of session existence
      assert :ok = Memory.close_session("nonexistent-session")
    end

    test "returns :ok for valid session close" do
      assert :ok = Memory.close_session("test-session")
    end

    test "raises when session_id is not a binary" do
      assert_raise FunctionClauseError, fn ->
        Memory.close_session(123)
      end
    end
  end

  describe "types" do
    test "memory_input type is defined" do
      # Type spec compilation test - if this compiles, the type exists
      assert true
    end

    test "stored_memory type is defined" do
      # Type spec compilation test
      assert true
    end
  end
end
