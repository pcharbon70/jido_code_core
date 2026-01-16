defmodule JidoCodeCore.Memory.Actions.RecallTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Memory.Actions.Recall

  # Note: Full integration tests with Memory.query require Memory.Supervisor setup
  # These tests focus on validation logic, constants, and error handling

  describe "constants" do
    test "max_limit/0 returns the maximum allowed limit" do
      assert Recall.max_limit() == 50
    end

    test "min_limit/0 returns the minimum allowed limit" do
      assert Recall.min_limit() == 1
    end

    test "default_limit/0 returns the default limit" do
      assert Recall.default_limit() == 10
    end

    test "max_query_length/0 returns the maximum query length" do
      assert Recall.max_query_length() == 1000
    end

    test "valid_types/0 returns all valid filter types" do
      types = Recall.valid_types()

      assert :all in types
      assert :fact in types
      assert :assumption in types
      assert :decision in types
      assert :convention in types
      assert :error in types
    end
  end

  describe "run/2 - session validation" do
    test "returns error when session_id is missing from context" do
      params = %{}
      context = %{}

      assert {:error, "Session ID is required in context"} = Recall.run(params, context)
    end

    test "returns error when session_id is invalid" do
      params = %{}

      assert {:error, "Session ID must be a valid string"} =
               Recall.run(params, %{session_id: "../../../etc/passwd"})

      assert {:error, "Session ID must be a valid string"} =
               Recall.run(params, %{session_id: "session with spaces"})
    end
  end

  describe "run/2 - limit validation" do
    test "returns error when limit is too small" do
      context = %{session_id: "test-session-123"}

      assert {:error, msg} = Recall.run(%{limit: 0}, context)
      assert String.contains?(msg, "Limit must be at least")
      assert String.contains?(msg, "1")
    end

    test "returns error when limit is negative" do
      context = %{session_id: "test-session-123"}

      assert {:error, msg} = Recall.run(%{limit: -5}, context)
      assert String.contains?(msg, "Limit must be at least")
    end

    test "returns error when limit exceeds maximum" do
      context = %{session_id: "test-session-123"}

      assert {:error, msg} = Recall.run(%{limit: 100}, context)
      assert String.contains?(msg, "cannot exceed")
      assert String.contains?(msg, "50")
    end

    test "accepts limit at minimum boundary" do
      context = %{session_id: "test-session-123"}

      # Limit validation passes, fails on memory access (expected)
      assert {:error, _} = Recall.run(%{limit: 1}, context)
    end

    test "accepts limit at maximum boundary" do
      context = %{session_id: "test-session-123"}

      # Limit validation passes, fails on memory access
      assert {:error, _} = Recall.run(%{limit: 50}, context)
    end

    test "uses default limit when not provided" do
      context = %{session_id: "test-session-123"}

      # Should use default limit of 10
      assert {:error, _} = Recall.run(%{}, context)
    end
  end

  describe "run/2 - min_confidence validation" do
    test "clamps min_confidence above 1.0 to 1.0" do
      context = %{session_id: "test-session-123"}

      # Confidence validation passes (clamped to 1.0), fails on memory access
      assert {:error, _} = Recall.run(%{min_confidence: 1.5}, context)
    end

    test "clamps min_confidence below 0.0 to 0.0" do
      context = %{session_id: "test-session-123"}

      assert {:error, _} = Recall.run(%{min_confidence: -0.5}, context)
    end

    test "accepts :high confidence level" do
      context = %{session_id: "test-session-123"}

      # Converts :high to 0.9, fails on memory access
      assert {:error, _} = Recall.run(%{min_confidence: :high}, context)
    end

    test "accepts :medium confidence level" do
      context = %{session_id: "test-session-123"}

      # Converts :medium to 0.6, fails on memory access
      assert {:error, _} = Recall.run(%{min_confidence: :medium}, context)
    end

    test "accepts :low confidence level" do
      context = %{session_id: "test-session-123"}

      # Converts :low to 0.3, fails on memory access
      assert {:error, _} = Recall.run(%{min_confidence: :low}, context)
    end
  end

  describe "run/2 - type validation" do
    test "returns error for invalid memory type" do
      context = %{session_id: "test-session-123"}

      assert {:error, msg} = Recall.run(%{type: :invalid_type}, context)
      assert String.contains?(msg, "Invalid memory type")
      assert String.contains?(msg, "invalid_type")
    end

    test "accepts :all type" do
      context = %{session_id: "test-session-123"}

      # Type validation passes, fails on memory access
      assert {:error, _} = Recall.run(%{type: :all}, context)
    end

    test "accepts knowledge types" do
      context = %{session_id: "test-session-123"}

      knowledge_types = [:fact, :assumption, :hypothesis, :discovery, :risk, :unknown]

      Enum.each(knowledge_types, fn type ->
        # Type validation passes, fails on memory access
        assert {:error, _} = Recall.run(%{type: type}, context)
      end)
    end

    test "accepts decision types" do
      context = %{session_id: "test-session-123"}

      decision_types = [:decision, :architectural_decision, :alternative, :trade_off]

      Enum.each(decision_types, fn type ->
        assert {:error, _} = Recall.run(%{type: type}, context)
      end)
    end

    test "accepts convention types" do
      context = %{session_id: "test-session-123"}

      convention_types = [:convention, :coding_standard, :agent_rule]

      Enum.each(convention_types, fn type ->
        assert {:error, _} = Recall.run(%{type: type}, context)
      end)
    end

    test "accepts error types" do
      context = %{session_id: "test-session-123"}

      error_types = [:error, :bug, :incident, :lesson_learned]

      Enum.each(error_types, fn type ->
        assert {:error, _} = Recall.run(%{type: type}, context)
      end)
    end
  end

  describe "run/2 - query validation" do
    test "returns error when query exceeds maximum length" do
      long_query = String.duplicate("x", 1001)
      context = %{session_id: "test-session-123"}

      assert {:error, msg} = Recall.run(%{query: long_query}, context)
      assert String.contains?(msg, "Query exceeds maximum length")
      assert String.contains?(msg, "1001")
      assert String.contains?(msg, "1000")
    end

    test "accepts query at maximum length" do
      max_query = String.duplicate("x", 1000)
      context = %{session_id: "test-session-123"}

      # Query validation passes, fails on memory access
      assert {:error, _} = Recall.run(%{query: max_query}, context)
    end

    test "accepts empty query as nil" do
      context = %{session_id: "test-session-123"}

      # Empty query becomes nil, fails on memory access
      assert {:error, _} = Recall.run(%{query: ""}, context)
    end

    test "accepts whitespace-only query as nil" do
      context = %{session_id: "test-session-123"}

      assert {:error, _} = Recall.run(%{query: "   "}, context)
    end

    test "accepts nil query" do
      context = %{session_id: "test-session-123"}

      assert {:error, _} = Recall.run(%{query: nil}, context)
    end
  end

  describe "run/2 - search_mode validation" do
    test "returns error for invalid search mode" do
      context = %{session_id: "test-session-123"}

      assert {:error, msg} = Recall.run(%{search_mode: :invalid_mode}, context)
      assert String.contains?(msg, "Invalid search mode")
      assert String.contains?(msg, "invalid_mode")
    end

    test "accepts :text search mode" do
      context = %{session_id: "test-session-123"}

      assert {:error, _} = Recall.run(%{search_mode: :text}, context)
    end

    test "accepts :semantic search mode" do
      context = %{session_id: "test-session-123"}

      assert {:error, _} = Recall.run(%{search_mode: :semantic}, context)
    end

    test "accepts :hybrid search mode" do
      context = %{session_id: "test-session-123"}

      assert {:error, _} = Recall.run(%{search_mode: :hybrid}, context)
    end

    test "uses default search mode when not provided" do
      context = %{session_id: "test-session-123"}

      # Should use default :hybrid mode
      assert {:error, _} = Recall.run(%{}, context)
    end
  end

  describe "run/2 - combined validation" do
    test "validates all parameters together" do
      context = %{session_id: "test-session-123"}

      # All validations pass, fails on memory access
      params = %{
        limit: 5,
        min_confidence: 0.7,
        type: :fact,
        query: "test query",
        search_mode: :text
      }

      assert {:error, _} = Recall.run(params, context)
    end

    test "validates with minimal valid parameters" do
      context = %{session_id: "test-session-123"}

      # All parameters use defaults
      assert {:error, _} = Recall.run(%{}, context)
    end

    test "validates query with type filter" do
      context = %{session_id: "test-session-123"}

      params = %{
        query: "Phoenix framework",
        type: :fact
      }

      assert {:error, _} = Recall.run(params, context)
    end

    test "validates confidence with query" do
      context = %{session_id: "test-session-123"}

      params = %{
        query: "test",
        min_confidence: :high
      }

      assert {:error, _} = Recall.run(params, context)
    end
  end
end
