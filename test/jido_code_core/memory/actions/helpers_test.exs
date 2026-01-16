defmodule JidoCodeCore.Memory.Actions.HelpersTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Memory.Actions.Helpers

  doctest Helpers

  describe "get_session_id/1" do
    test "returns ok with session_id when present and valid" do
      context = %{session_id: "session-123"}
      assert {:ok, "session-123"} = Helpers.get_session_id(context)
    end

    test "returns ok with valid session_id containing hyphens and underscores" do
      context = %{session_id: "my_session_123-456"}
      assert {:ok, "my_session_123-456"} = Helpers.get_session_id(context)
    end

    test "returns error when session_id is missing" do
      context = %{}
      assert {:error, :missing_session_id} = Helpers.get_session_id(context)
    end

    test "returns error when session_id is nil" do
      context = %{session_id: nil}
      assert {:error, :missing_session_id} = Helpers.get_session_id(context)
    end

    test "returns error when session_id is invalid (path traversal)" do
      context = %{session_id: "../../../etc/passwd"}
      assert {:error, :invalid_session_id} = Helpers.get_session_id(context)
    end

    test "returns error when session_id is invalid (spaces)" do
      context = %{session_id: "session with spaces"}
      assert {:error, :invalid_session_id} = Helpers.get_session_id(context)
    end

    test "returns error when session_id is not a binary" do
      context = %{session_id: 123}
      assert {:error, :invalid_session_id} = Helpers.get_session_id(context)
    end

    test "returns error when session_id is empty string" do
      context = %{session_id: ""}
      assert {:error, :invalid_session_id} = Helpers.get_session_id(context)
    end
  end

  describe "validate_confidence/3" do
    test "returns ok with clamped value when confidence is numeric" do
      assert {:ok, 0.5} = Helpers.validate_confidence(%{confidence: 0.5}, :confidence, 0.8)
    end

    test "clamps confidence above 1.0 to 1.0" do
      assert {:ok, 1.0} = Helpers.validate_confidence(%{confidence: 1.5}, :confidence, 0.8)
    end

    test "clamps confidence below 0.0 to 0.0" do
      assert {:ok, 0.0} = Helpers.validate_confidence(%{confidence: -0.5}, :confidence, 0.8)
    end

    test "converts :high level to confidence" do
      assert {:ok, 0.9} = Helpers.validate_confidence(%{confidence: :high}, :confidence, 0.8)
    end

    test "converts :medium level to confidence" do
      assert {:ok, 0.6} = Helpers.validate_confidence(%{confidence: :medium}, :confidence, 0.8)
    end

    test "converts :low level to confidence" do
      assert {:ok, 0.3} = Helpers.validate_confidence(%{confidence: :low}, :confidence, 0.8)
    end

    test "returns default when confidence is nil" do
      assert {:ok, 0.8} = Helpers.validate_confidence(%{}, :confidence, 0.8)
    end

    test "returns default when confidence is invalid atom" do
      assert {:ok, 0.8} = Helpers.validate_confidence(%{confidence: :invalid}, :confidence, 0.8)
    end

    test "returns default when key not in params" do
      assert {:ok, 0.5} = Helpers.validate_confidence(%{other: 0.9}, :confidence, 0.5)
    end
  end

  describe "format_common_error/1" do
    test "formats missing_session_id error" do
      assert Helpers.format_common_error(:missing_session_id) == "Session ID is required in context"
    end

    test "formats invalid_session_id error" do
      assert Helpers.format_common_error(:invalid_session_id) == "Session ID must be a valid string"
    end

    test "returns nil for unrecognized errors" do
      assert Helpers.format_common_error(:unknown_error) == nil
    end

    test "returns nil for string errors" do
      assert Helpers.format_common_error("some error") == nil
    end
  end

  describe "validate_non_empty_string/1" do
    test "returns ok with trimmed string for valid input" do
      assert {:ok, "hello"} = Helpers.validate_non_empty_string("hello")
    end

    test "trims whitespace from valid string" do
      assert {:ok, "hello"} = Helpers.validate_non_empty_string("  hello  ")
    end

    test "returns error for empty string" do
      assert {:error, :empty_string} = Helpers.validate_non_empty_string("")
    end

    test "returns error for whitespace-only string" do
      assert {:error, :empty_string} = Helpers.validate_non_empty_string("   ")
    end

    test "returns error for nil" do
      assert {:error, :not_a_string} = Helpers.validate_non_empty_string(nil)
    end

    test "returns error for non-string value" do
      assert {:error, :not_a_string} = Helpers.validate_non_empty_string(123)
    end

    test "returns error for list" do
      assert {:error, :not_a_string} = Helpers.validate_non_empty_string(["value"])
    end

    test "returns error for map" do
      assert {:error, :not_a_string} = Helpers.validate_non_empty_string(%{value: "x"})
    end
  end

  describe "validate_bounded_string/2" do
    test "returns ok with trimmed string when within limit" do
      assert {:ok, "hello"} = Helpers.validate_bounded_string("hello", 100)
    end

    test "trims whitespace" do
      assert {:ok, "hello"} = Helpers.validate_bounded_string("  hello  ", 100)
    end

    test "returns error for empty string" do
      assert {:error, :empty_string} = Helpers.validate_bounded_string("", 100)
    end

    test "returns error when string exceeds max length" do
      assert {:error, {:too_long, 5, 3}} = Helpers.validate_bounded_string("hello", 3)
    end

    test "trims then checks length - passes when trimmed fits" do
      # "  hello  " becomes "hello" (5 chars) which fits in 5
      assert {:ok, "hello"} = Helpers.validate_bounded_string("  hello  ", 5)
    end

    test "returns error for nil" do
      assert {:error, :not_a_string} = Helpers.validate_bounded_string(nil, 100)
    end

    test "returns error for non-string value" do
      assert {:error, :not_a_string} = Helpers.validate_bounded_string(123, 100)
    end

    test "allows string exactly at max length" do
      assert {:ok, "hello"} = Helpers.validate_bounded_string("hello", 5)
    end
  end

  describe "validate_optional_string/1" do
    test "returns ok with trimmed string for valid input" do
      assert {:ok, "hello"} = Helpers.validate_optional_string("hello")
    end

    test "returns ok with nil for empty string" do
      assert {:ok, nil} = Helpers.validate_optional_string("")
    end

    test "returns ok with nil for whitespace-only string" do
      assert {:ok, nil} = Helpers.validate_optional_string("   ")
    end

    test "returns ok with nil for nil input" do
      assert {:ok, nil} = Helpers.validate_optional_string(nil)
    end

    test "returns ok with nil for non-string value" do
      assert {:ok, nil} = Helpers.validate_optional_string(123)
    end

    test "trims whitespace from valid string" do
      assert {:ok, "hello"} = Helpers.validate_optional_string("  hello  ")
    end
  end

  describe "validate_optional_bounded_string/2" do
    test "returns ok with trimmed string when within limit" do
      assert {:ok, "hello"} = Helpers.validate_optional_bounded_string("hello", 100)
    end

    test "returns ok with nil for empty string" do
      assert {:ok, nil} = Helpers.validate_optional_bounded_string("", 100)
    end

    test "returns ok with nil for whitespace-only string" do
      assert {:ok, nil} = Helpers.validate_optional_bounded_string("   ", 100)
    end

    test "returns ok with nil for nil input" do
      assert {:ok, nil} = Helpers.validate_optional_bounded_string(nil, 100)
    end

    test "returns ok with nil for non-string value" do
      assert {:ok, nil} = Helpers.validate_optional_bounded_string(123, 100)
    end

    test "returns error when string exceeds max length" do
      assert {:error, {:too_long, 5, 3}} = Helpers.validate_optional_bounded_string("hello", 3)
    end

    test "allows string exactly at max length" do
      assert {:ok, "hello"} = Helpers.validate_optional_bounded_string("hello", 5)
    end

    test "trims whitespace before checking length - passes when trimmed fits" do
      # "  hello  " becomes "hello" (5 chars) which fits in 5
      assert {:ok, "hello"} = Helpers.validate_optional_bounded_string("  hello  ", 5)
    end
  end

  describe "format_timestamp/1" do
    test "formats DateTime to ISO8601 string" do
      dt = DateTime.from_unix!(1_670_000_000)
      result = Helpers.format_timestamp(dt)
      assert is_binary(result)
      assert String.contains?(result, "T")
    end

    test "returns nil for nil input" do
      assert Helpers.format_timestamp(nil) == nil
    end

    test "returns inspect string for other types" do
      assert Helpers.format_timestamp(123) == "123"
      assert Helpers.format_timestamp(:atom) == ":atom"
      assert Helpers.format_timestamp([1, 2, 3]) == "[1, 2, 3]"
    end
  end

  describe "integration tests" do
    test "full validation workflow for session with valid inputs" do
      context = %{session_id: "test-session-123"}

      assert {:ok, "test-session-123"} = Helpers.get_session_id(context)
      assert {:ok, 0.8} = Helpers.validate_confidence(%{confidence: 0.8}, :confidence, 0.5)
      assert {:ok, "content"} = Helpers.validate_non_empty_string("content")
    end

    test "validation workflow catches invalid inputs" do
      # Invalid session ID
      assert {:error, :invalid_session_id} = Helpers.get_session_id(%{session_id: ""})

      # Invalid confidence gets clamped
      assert {:ok, 1.0} = Helpers.validate_confidence(%{confidence: 2.0}, :confidence, 0.5)

      # Empty string fails validation
      assert {:error, :empty_string} = Helpers.validate_non_empty_string("")
    end

    test "optional string validation handles edge cases" do
      assert {:ok, nil} = Helpers.validate_optional_string(nil)
      assert {:ok, nil} = Helpers.validate_optional_string("")
      assert {:ok, nil} = Helpers.validate_optional_string("  ")
      assert {:ok, "value"} = Helpers.validate_optional_string("  value  ")
    end
  end
end
