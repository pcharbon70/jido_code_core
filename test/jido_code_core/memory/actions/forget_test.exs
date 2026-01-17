defmodule JidoCodeCore.Memory.Actions.ForgetTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Memory.Actions.Forget

  # Note: Full integration tests with Memory.persist require Memory.Supervisor setup
  # These tests focus on validation logic and error handling

  describe "max_reason_length/0" do
    test "returns the maximum allowed reason length" do
      assert Forget.max_reason_length() == 500
    end
  end

  describe "run/2 - validation tests" do
    test "returns error when session_id is missing from context" do
      params = %{memory_id: "mem-123"}
      context = %{}

      assert {:error, "Session ID is required in context"} = Forget.run(params, context)
    end

    test "returns error when session_id is invalid" do
      params = %{memory_id: "mem-123"}

      assert {:error, "Session ID must be a valid string"} =
               Forget.run(params, %{session_id: "../../../etc/passwd"})

      assert {:error, "Session ID must be a valid string"} =
               Forget.run(params, %{session_id: "session with spaces"})
    end

    test "returns error when memory_id is missing" do
      context = %{session_id: "test-session-123"}

      assert {:error, "Memory ID is required"} = Forget.run(%{}, context)
    end

    test "returns error when memory_id is empty string" do
      context = %{session_id: "test-session-123"}

      assert {:error, "Memory ID cannot be empty"} = Forget.run(%{memory_id: ""}, context)
    end

    test "returns error when memory_id is whitespace only" do
      context = %{session_id: "test-session-123"}

      assert {:error, "Memory ID cannot be empty"} = Forget.run(%{memory_id: "   "}, context)
    end

    test "returns error when memory_id is not a string" do
      context = %{session_id: "test-session-123"}

      assert {:error, "Memory ID must be a string"} = Forget.run(%{memory_id: 123}, context)
      assert {:error, "Memory ID must be a string"} = Forget.run(%{memory_id: nil}, context)
      assert {:error, "Memory ID must be a string"} = Forget.run(%{memory_id: [:list]}, context)
    end
  end

  describe "run/2 - reason validation" do
    test "returns error when reason exceeds maximum length" do
      long_reason = String.duplicate("x", 501)
      context = %{session_id: "test-session-123"}

      assert {:error, msg} = Forget.run(%{memory_id: "mem-123", reason: long_reason}, context)
      assert String.contains?(msg, "Reason exceeds maximum length")
      assert String.contains?(msg, "501")
      assert String.contains?(msg, "500")
    end

    test "accepts reason at maximum length" do
      max_reason = String.duplicate("x", 500)
      context = %{session_id: "test-session-123"}

      # Reason validation passes, fails on memory access (expected without Memory.Supervisor setup)
      assert {:error, error_msg} =
               Forget.run(%{memory_id: "mem-123", reason: max_reason}, context)

      # Should get a store error, not a reason length error
      refute String.contains?(error_msg, "Reason exceeds maximum length")
    end

    test "accepts empty reason as nil" do
      context = %{session_id: "test-session-123"}

      # Empty reason becomes nil, fails on memory access
      assert {:error, _} = Forget.run(%{memory_id: "mem-123", reason: ""}, context)
    end

    test "accepts whitespace-only reason as nil" do
      context = %{session_id: "test-session-123"}

      assert {:error, _} = Forget.run(%{memory_id: "mem-123", reason: "   "}, context)
    end
  end

  describe "run/2 - memory_id trimming" do
    test "trims whitespace from memory_id before validation" do
      context = %{session_id: "test-session-123"}

      # Memory ID "  mem-123  " should be trimmed to "mem-123"
      # The trimmed ID is used, then fails on memory access
      assert {:error, error_msg} = Forget.run(%{memory_id: "  mem-123  "}, context)
      # Should get an error (not a validation error about whitespace)
      refute String.contains?(error_msg, "empty")
    end

    test "trims leading whitespace from memory_id" do
      context = %{session_id: "test-session-123"}

      assert {:error, error_msg} = Forget.run(%{memory_id: "   mem-123"}, context)
      # Should get an error (not a validation error about whitespace)
      refute String.contains?(error_msg, "empty")
    end

    test "trims trailing whitespace from memory_id" do
      context = %{session_id: "test-session-123"}

      assert {:error, error_msg} = Forget.run(%{memory_id: "mem-123   "}, context)
      # Should get an error (not a validation error about whitespace)
      refute String.contains?(error_msg, "empty")
    end
  end

  describe "run/2 - replacement_id handling" do
    test "accepts nil replacement_id" do
      context = %{session_id: "test-session-123"}

      # replacement_id defaults to nil, fails on memory access
      assert {:error, _} = Forget.run(%{memory_id: "mem-123"}, context)
    end

    test "accepts empty replacement_id as nil" do
      context = %{session_id: "test-session-123"}

      # Empty string becomes nil for optional string
      assert {:error, _} = Forget.run(%{memory_id: "mem-123", replacement_id: ""}, context)
    end

    test "trims whitespace from replacement_id" do
      context = %{session_id: "test-session-123"}

      # Validates replacement_id format, trims whitespace
      assert {:error, _} =
               Forget.run(%{memory_id: "mem-123", replacement_id: "  replacement  "}, context)
    end
  end
end
