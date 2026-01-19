defmodule JidoCodeCore.ErrorsTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Errors

  describe "Errors.Session" do
    test "SessionNotFound exception" do
      error = Errors.Session.SessionNotFound.exception(session_id: "abc123")

      assert error.message == "Session 'abc123' not found"
      assert error.session_id == "abc123"
      assert error.details == %{}
    end

    test "SessionNotFound without session_id" do
      error = Errors.Session.SessionNotFound.exception([])

      assert error.message == "Session not found"
      assert error.session_id == nil
    end

    test "SessionInvalidState exception" do
      error =
        Errors.Session.SessionInvalidState.exception(
          session_id: "abc123",
          current_state: :stopped,
          required_state: :running
        )

      assert error.message =~ "Session 'abc123' is in invalid state"
      assert error.session_id == "abc123"
      assert error.current_state == :stopped
      assert error.required_state == :running
    end

    test "SessionConfigError exception" do
      error = Errors.Session.SessionConfigError.exception(missing_key: :model)

      assert error.message =~ "missing required key: :model"
      assert error.missing_key == :model
    end

    test "SessionConfigError with invalid_key" do
      error =
        Errors.Session.SessionConfigError.exception(
          invalid_key: :max_tokens,
          config: %{max_tokens: "invalid"}
        )

      assert error.message =~ "invalid value for: :max_tokens"
      assert error.invalid_key == :max_tokens
    end
  end

  describe "Errors.Tools" do
    test "ToolNotFound exception" do
      error = Errors.Tools.ToolNotFound.exception(tool_name: "read_file")

      assert error.message == "Tool 'read_file' not found in registry"
      assert error.tool_name == "read_file"
    end

    test "ToolExecutionFailed exception" do
      error =
        Errors.Tools.ToolExecutionFailed.exception(
          tool_name: "read_file",
          reason: :enoent
        )

      assert error.message == "Tool 'read_file' execution failed: enoent"
      assert error.tool_name == "read_file"
      assert error.reason == :enoent
    end

    test "ToolTimeout exception" do
      error =
        Errors.Tools.ToolTimeout.exception(
          tool_name: "slow_operation",
          timeout_ms: 30000
        )

      assert error.message == "Tool 'slow_operation' execution timed out after 30000ms"
      assert error.tool_name == "slow_operation"
      assert error.timeout_ms == 30000
    end

    test "ToolValidationFailed exception" do
      error =
        Errors.Tools.ToolValidationFailed.exception(
          tool_name: "read_file",
          errors: [%{path: "required"}]
        )

      assert error.message == "Tool 'read_file' parameter validation failed"
      assert error.tool_name == "read_file"
      assert error.errors == [%{path: "required"}]
    end
  end

  describe "Errors.Memory" do
    test "MemoryNotFound exception" do
      error = Errors.Memory.MemoryNotFound.exception(memory_id: "mem-123")

      assert error.message == "Memory 'mem-123' not found"
      assert error.memory_id == "mem-123"
    end

    test "MemoryNotFound with query" do
      error =
        Errors.Memory.MemoryNotFound.exception(query: "what did i work on yesterday")

      assert error.message =~ "No memories found matching query"
      assert error.query == "what did i work on yesterday"
    end

    test "MemoryStorageFailed exception" do
      error = Errors.Memory.MemoryStorageFailed.exception(reason: "disk full")

      assert error.message == "Failed to store memory: disk full"
      assert error.reason == "disk full"
    end

    test "MemoryPromotionFailed exception" do
      error =
        Errors.Memory.MemoryPromotionFailed.exception(
          memory_id: "mem-123",
          reason: :triple_store_unavailable
        )

      assert error.message =~ "Failed to promote memory 'mem-123'"
      assert error.memory_id == "mem-123"
      assert error.reason == :triple_store_unavailable
    end
  end

  describe "Errors.Validation" do
    test "InvalidParameters exception" do
      error =
        Errors.Validation.InvalidParameters.exception(
          field: :path,
          value: nil
        )

      assert error.message =~ "Invalid value for field ':path'"
      assert error.field == :path
      assert error.value == nil
    end

    test "InvalidParameters with custom message" do
      error =
        Errors.Validation.InvalidParameters.exception(
          message: "path is required"
        )

      assert error.message == "path is required"
    end

    test "SchemaValidationFailed exception" do
      error =
        Errors.Validation.SchemaValidationFailed.exception(
          schema: "ToolParams",
          errors: [%{path: [:path], message: "is required"}]
        )

      assert error.message == "Schema validation failed for 'ToolParams'"
      assert error.schema == "ToolParams"
      assert error.errors == [%{path: [:path], message: "is required"}]
    end

    test "InvalidSessionId exception" do
      error =
        Errors.Validation.InvalidSessionId.exception(
          session_id: "not-a-uuid",
          reason: :invalid_format
        )

      assert error.message == "Invalid session ID: 'not-a-uuid'"
      assert error.session_id == "not-a-uuid"
      assert error.reason == :invalid_format
    end
  end

  describe "Errors.Agent" do
    test "AgentNotRunning exception" do
      error =
        Errors.Agent.AgentNotRunning.exception(
          agent_id: "agent-1",
          state: :stopped
        )

      assert error.message == "Agent 'agent-1' is not running (current state: :stopped)"
      assert error.agent_id == "agent-1"
      assert error.state == :stopped
    end

    test "AgentStartupFailed exception" do
      error =
        Errors.Agent.AgentStartupFailed.exception(
          agent_id: "agent-1",
          reason: "configuration_error"
        )

      assert error.message == "Agent 'agent-1' failed to start: configuration_error"
      assert error.agent_id == "agent-1"
      assert error.reason == "configuration_error"
    end

    test "AgentTimeout exception" do
      error =
        Errors.Agent.AgentTimeout.exception(
          agent_id: "agent-1",
          operation: :run_action,
          timeout_ms: 5000
        )

      assert error.message == "Agent 'agent-1' operation 'run_action' timed out after 5000ms"
      assert error.agent_id == "agent-1"
      assert error.operation == :run_action
      assert error.timeout_ms == 5000
    end
  end

  describe "Errors.normalize/1" do
    test "normalizes {:error, reason} tuples" do
      error = Errors.normalize({:error, :not_found})
      assert error.message == "not_found"
    end

    test "normalizes binary errors" do
      error = Errors.normalize("something went wrong")
      assert error.message == "something went wrong"
    end

    test "normalizes atom errors" do
      error = Errors.normalize(:enoent)
      assert error.message == "enoent"
    end

    test "returns existing error structs unchanged" do
      original = Errors.Session.SessionNotFound.exception(session_id: "test")
      normalized = Errors.normalize(original)
      assert normalized == original
    end
  end

  describe "Errors.message/1" do
    test "extracts message from error struct" do
      error = Errors.Session.SessionNotFound.exception(session_id: "test")
      assert Errors.message(error) == "Session 'test' not found"
    end

    test "handles nested message structs" do
      error = Errors.Validation.InvalidParameters.exception(field: :test)
      assert Errors.message(error) =~ "Invalid value"
    end
  end

  describe "Splode integration" do
    test "error classes are Splode-compatible" do
      # All error classes should be raise-able and catchable
      assert_raise Errors.Session.SessionNotFound, ~r/not found/, fn ->
        raise Errors.Session.SessionNotFound, session_id: "test"
      end

      assert_raise Errors.Tools.ToolNotFound, ~r/not found/, fn ->
        raise Errors.Tools.ToolNotFound, tool_name: "test_tool"
      end
    end
  end
end
