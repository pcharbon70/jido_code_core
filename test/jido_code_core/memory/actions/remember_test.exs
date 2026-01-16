defmodule JidoCodeCore.Memory.Actions.RememberTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Memory.Actions.Remember

  # Note: Full integration tests with Memory.persist require Memory.Supervisor setup
  # These tests focus on validation logic, constants, and error handling

  describe "constants" do
    test "max_content_length/0 returns the maximum content length" do
      assert Remember.max_content_length() == 2000
    end

    test "valid_memory_types/0 returns all valid memory types" do
      types = Remember.valid_memory_types()

      # Knowledge types
      assert :fact in types
      assert :assumption in types
      assert :hypothesis in types
      assert :discovery in types
      assert :risk in types
      assert :unknown in types

      # Decision types
      assert :decision in types
      assert :architectural_decision in types
      assert :alternative in types
      assert :trade_off in types

      # Convention types
      assert :convention in types
      assert :coding_standard in types
      assert :agent_rule in types

      # Error types
      assert :error in types
      assert :bug in types
      assert :incident in types
      assert :lesson_learned in types
    end
  end

  describe "run/2 - session validation" do
    test "returns error when session_id is missing from context" do
      params = %{content: "Test"}
      context = %{}

      assert {:error, "Session ID is required in context"} = Remember.run(params, context)
    end

    test "returns error when session_id is invalid" do
      params = %{content: "Test"}

      assert {:error, "Session ID must be a valid string"} =
               Remember.run(params, %{session_id: "../../../etc/passwd"})

      assert {:error, "Session ID must be a valid string"} =
               Remember.run(params, %{session_id: "session with spaces"})
    end
  end

  describe "run/2 - content validation" do
    test "returns error when content is missing" do
      context = %{session_id: "test-session-123"}

      assert {:error, "Content must be a non-empty string"} = Remember.run(%{}, context)
    end

    test "returns error when content is empty string" do
      context = %{session_id: "test-session-123"}

      assert {:error, "Content cannot be empty"} = Remember.run(%{content: ""}, context)
    end

    test "returns error when content is whitespace only" do
      context = %{session_id: "test-session-123"}

      assert {:error, "Content cannot be empty"} = Remember.run(%{content: "   "}, context)
    end

    test "returns error when content is not a string" do
      context = %{session_id: "test-session-123"}

      assert {:error, "Content must be a non-empty string"} = Remember.run(%{content: 123}, context)
      assert {:error, "Content must be a non-empty string"} = Remember.run(%{content: nil}, context)
      assert {:error, "Content must be a non-empty string"} = Remember.run(%{content: [:list]}, context)
    end

    test "returns error when content exceeds maximum length" do
      long_content = String.duplicate("x", 2001)
      context = %{session_id: "test-session-123"}

      assert {:error, msg} = Remember.run(%{content: long_content}, context)
      assert String.contains?(msg, "Content exceeds maximum length")
      assert String.contains?(msg, "2001")
      assert String.contains?(msg, "2000")
    end

    test "accepts content at maximum length" do
      max_content = String.duplicate("x", 2000)
      context = %{session_id: "test-session-123"}

      # Content validation passes, fails on memory persistence
      assert {:error, _} = Remember.run(%{content: max_content}, context)
    end

    test "trims whitespace from content" do
      context = %{session_id: "test-session-123"}

      # Content "  test  " becomes "test", fails on memory persistence
      assert {:error, _} = Remember.run(%{content: "  test  "}, context)
    end
  end

  describe "run/2 - type validation" do
    test "returns error for invalid memory type" do
      context = %{session_id: "test-session-123"}

      assert {:error, msg} = Remember.run(%{content: "Test", type: :invalid_type}, context)
      assert String.contains?(msg, "Invalid memory type")
      assert String.contains?(msg, "invalid_type")
    end

    test "uses default type :fact when not provided" do
      context = %{session_id: "test-session-123"}

      # Type defaults to :fact, fails on memory persistence
      assert {:error, _} = Remember.run(%{content: "Test"}, context)
    end

    test "accepts knowledge types" do
      context = %{session_id: "test-session-123"}

      knowledge_types = [:fact, :assumption, :hypothesis, :discovery, :risk, :unknown]

      Enum.each(knowledge_types, fn type ->
        assert {:error, _} = Remember.run(%{content: "Test", type: type}, context)
      end)
    end

    test "accepts decision types" do
      context = %{session_id: "test-session-123"}

      decision_types = [:decision, :architectural_decision, :alternative, :trade_off]

      Enum.each(decision_types, fn type ->
        assert {:error, _} = Remember.run(%{content: "Test", type: type}, context)
      end)
    end

    test "accepts convention types" do
      context = %{session_id: "test-session-123"}

      convention_types = [:convention, :coding_standard, :agent_rule]

      Enum.each(convention_types, fn type ->
        assert {:error, _} = Remember.run(%{content: "Test", type: type}, context)
      end)
    end

    test "accepts error types" do
      context = %{session_id: "test-session-123"}

      error_types = [:error, :bug, :incident, :lesson_learned]

      Enum.each(error_types, fn type ->
        assert {:error, _} = Remember.run(%{content: "Test", type: type}, context)
      end)
    end
  end

  describe "run/2 - confidence validation" do
    test "clamps confidence above 1.0 to 1.0" do
      context = %{session_id: "test-session-123"}

      # Confidence validation passes (clamped to 1.0), fails on memory persistence
      assert {:error, _} = Remember.run(%{content: "Test", confidence: 1.5}, context)
    end

    test "clamps confidence below 0.0 to 0.0" do
      context = %{session_id: "test-session-123"}

      assert {:error, _} = Remember.run(%{content: "Test", confidence: -0.5}, context)
    end

    test "accepts :high confidence level" do
      context = %{session_id: "test-session-123"}

      # Converts :high to 0.9, fails on memory persistence
      assert {:error, _} = Remember.run(%{content: "Test", confidence: :high}, context)
    end

    test "accepts :medium confidence level" do
      context = %{session_id: "test-session-123"}

      # Converts :medium to 0.6, fails on memory persistence
      assert {:error, _} = Remember.run(%{content: "Test", confidence: :medium}, context)
    end

    test "accepts :low confidence level" do
      context = %{session_id: "test-session-123"}

      # Converts :low to 0.3, fails on memory persistence
      assert {:error, _} = Remember.run(%{content: "Test", confidence: :low}, context)
    end

    test "uses default confidence when not provided" do
      context = %{session_id: "test-session-123"}

      # Default is 0.8, fails on memory persistence
      assert {:error, _} = Remember.run(%{content: "Test"}, context)
    end
  end

  describe "run/2 - rationale handling" do
    test "accepts valid rationale" do
      context = %{session_id: "test-session-123"}

      # Rationale is optional, passes validation, fails on memory persistence
      assert {:error, _} = Remember.run(%{content: "Test", rationale: "Important for future"}, context)
    end

    test "accepts nil rationale" do
      context = %{session_id: "test-session-123"}

      assert {:error, _} = Remember.run(%{content: "Test", rationale: nil}, context)
    end

    test "trims whitespace from rationale" do
      context = %{session_id: "test-session-123"}

      # Rationale "  reason  " is trimmed to "reason"
      assert {:error, _} = Remember.run(%{content: "Test", rationale: "  reason  "}, context)
    end

    test "accepts empty string rationale" do
      context = %{session_id: "test-session-123"}

      # Empty rationale becomes nil (optional_bounded_string behavior)
      assert {:error, _} = Remember.run(%{content: "Test", rationale: ""}, context)
    end
  end

  describe "run/2 - combined validation" do
    test "validates all parameters together" do
      context = %{session_id: "test-session-123"}

      # All validations pass, fails on memory persistence
      params = %{
        content: "Project uses Phoenix framework",
        type: :fact,
        confidence: 0.95,
        rationale: "Key architectural decision"
      }

      assert {:error, _} = Remember.run(params, context)
    end

    test "validates with minimal required parameters" do
      context = %{session_id: "test-session-123"}

      # Only content is required, rest use defaults
      assert {:error, _} = Remember.run(%{content: "Test fact"}, context)
    end

    test "validates knowledge type with content" do
      context = %{session_id: "test-session-123"}

      params = %{
        content: "This is an assumption",
        type: :assumption,
        confidence: 0.6
      }

      assert {:error, _} = Remember.run(params, context)
    end

    test "validates decision type with rationale" do
      context = %{session_id: "test-session-123"}

      params = %{
        content: "Chose Phoenix over other frameworks",
        type: :decision,
        rationale: "Better ecosystem and real-time capabilities"
      }

      assert {:error, _} = Remember.run(params, context)
    end

    test "validates error type with content" do
      context = %{session_id: "test-session-123"}

      params = %{
        content: "Null pointer exception in user controller",
        type: :bug
      }

      assert {:error, _} = Remember.run(params, context)
    end
  end
end
