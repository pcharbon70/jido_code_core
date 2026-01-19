defmodule JidoCodeCore.Errors.Agent do
  @moduledoc """
  Agent-related errors.

  ## Error Types

  - `AgentNotRunning` - Agent is not running
  - `AgentStartupFailed` - Agent failed to start
  - `AgentTimeout` - Agent operation timed out

  ## Examples

      raise Errors.Agent.AgentNotRunning.exception(
        agent_id: "agent-1",
        state: :stopped
      )

      raise Errors.Agent.AgentStartupFailed.exception(
        agent_id: "agent-1",
        reason: "configuration_error"
      )

      raise Errors.Agent.AgentTimeout.exception(
        agent_id: "agent-1",
        operation: :run_action,
        timeout_ms: 5000
      )
  """

  defmodule AgentNotRunning do
    @moduledoc """
    Error raised when an agent is not running.
    """
    defexception [:message, :agent_id, :state, :details]

    @impl true
    def exception(opts) do
      agent_id = Keyword.get(opts, :agent_id)
      state = Keyword.get(opts, :state)
      details = Keyword.get(opts, :details, %{})

      message =
        case {agent_id, state} do
          {nil, nil} -> "Agent is not running"
          {id, nil} -> "Agent '#{id}' is not running"
          {nil, s} -> "Agent is not running (current state: #{inspect(s)})"
          {id, s} -> "Agent '#{id}' is not running (current state: #{inspect(s)})"
        end

      %__MODULE__{
        message: message,
        agent_id: agent_id,
        state: state,
        details: details
      }
    end
  end

  defmodule AgentStartupFailed do
    @moduledoc """
    Error raised when an agent fails to start.
    """
    defexception [:message, :agent_id, :reason, :details]

    @impl true
    def exception(opts) do
      agent_id = Keyword.get(opts, :agent_id)
      reason = Keyword.get(opts, :reason)
      details = Keyword.get(opts, :details, %{})

      message =
        case {agent_id, reason} do
          {nil, nil} -> "Agent failed to start"
          {id, nil} -> "Agent '#{id}' failed to start"
          {nil, r} -> "Agent failed to start: #{format_reason(r)}"
          {id, r} -> "Agent '#{id}' failed to start: #{format_reason(r)}"
        end

      %__MODULE__{
        message: message,
        agent_id: agent_id,
        reason: reason,
        details: details
      }
    end

    defp format_reason(reason) when is_binary(reason), do: reason
    defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
    defp format_reason(reason), do: inspect(reason)
  end

  defmodule AgentTimeout do
    @moduledoc """
    Error raised when an agent operation times out.
    """
    defexception [:message, :agent_id, :operation, :timeout_ms, :details]

    @impl true
    def exception(opts) do
      agent_id = Keyword.get(opts, :agent_id)
      operation = Keyword.get(opts, :operation)
      timeout_ms = Keyword.get(opts, :timeout_ms)
      details = Keyword.get(opts, :details, %{})

      message =
        case {agent_id, operation, timeout_ms} do
          {nil, nil, nil} -> "Agent operation timed out"
          {id, nil, nil} -> "Agent '#{id}' operation timed out"
          {nil, op, nil} -> "Agent operation '#{format_operation(op)}' timed out"
          {nil, nil, ms} -> "Agent operation timed out after #{ms}ms"
          {id, op, nil} -> "Agent '#{id}' operation '#{format_operation(op)}' timed out"
          {id, nil, ms} -> "Agent '#{id}' operation timed out after #{ms}ms"
          {id, op, ms} -> "Agent '#{id}' operation '#{format_operation(op)}' timed out after #{ms}ms"
        end

      %__MODULE__{
        message: message,
        agent_id: agent_id,
        operation: operation,
        timeout_ms: timeout_ms,
        details: details
      }
    end

    defp format_operation(op) when is_binary(op), do: op
    defp format_operation(op) when is_atom(op), do: Atom.to_string(op)
    defp format_operation(op), do: inspect(op)
  end
end
