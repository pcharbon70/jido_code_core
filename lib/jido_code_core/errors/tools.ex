defmodule JidoCodeCore.Errors.Tools do
  @moduledoc """
  Tool-related errors.

  ## Error Types

  - `ToolNotFound` - Tool does not exist in registry
  - `ToolExecutionFailed` - Tool execution failed
  - `ToolTimeout` - Tool execution timed out
  - `ToolValidationFailed` - Tool parameters failed validation

  ## Examples

      raise Errors.Tools.ToolNotFound.exception(tool_name: "read_file")

      raise Errors.Tools.ToolExecutionFailed.exception(
        tool_name: "read_file",
        reason: :file_not_found
      )

      raise Errors.Tools.ToolTimeout.exception(
        tool_name: "slow_operation",
        timeout_ms: 30000
      )

      raise Errors.Tools.ToolValidationFailed.exception(
        tool_name: "read_file",
        errors: [%{path: "required", value: nil}]
      )
  """

  defmodule ToolNotFound do
    @moduledoc """
    Error raised when a tool is not found in the registry.
    """
    defexception [:message, :tool_name, :details]

    @impl true
    def exception(opts) do
      tool_name = Keyword.get(opts, :tool_name)
      details = Keyword.get(opts, :details, %{})

      message =
        case tool_name do
          nil -> "Tool not found"
          name when is_binary(name) -> "Tool '#{name}' not found in registry"
        end

      %__MODULE__{
        message: message,
        tool_name: tool_name,
        details: details
      }
    end
  end

  defmodule ToolExecutionFailed do
    @moduledoc """
    Error raised when a tool execution fails.
    """
    defexception [:message, :tool_name, :reason, :details]

    @impl true
    def exception(opts) do
      tool_name = Keyword.get(opts, :tool_name)
      reason = Keyword.get(opts, :reason)
      details = Keyword.get(opts, :details, %{})

      message =
        case {tool_name, reason} do
          {nil, nil} -> "Tool execution failed"
          {name, nil} -> "Tool '#{name}' execution failed"
          {nil, reason} -> "Tool execution failed: #{format_reason(reason)}"
          {name, reason} -> "Tool '#{name}' execution failed: #{format_reason(reason)}"
        end

      %__MODULE__{
        message: message,
        tool_name: tool_name,
        reason: reason,
        details: details
      }
    end

    defp format_reason(reason) when is_binary(reason), do: reason
    defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
    defp format_reason(reason), do: inspect(reason)
  end

  defmodule ToolTimeout do
    @moduledoc """
    Error raised when a tool execution times out.
    """
    defexception [:message, :tool_name, :timeout_ms, :details]

    @impl true
    def exception(opts) do
      tool_name = Keyword.get(opts, :tool_name)
      timeout_ms = Keyword.get(opts, :timeout_ms)
      details = Keyword.get(opts, :details, %{})

      message =
        case {tool_name, timeout_ms} do
          {nil, nil} -> "Tool execution timed out"
          {name, nil} -> "Tool '#{name}' execution timed out"
          {nil, ms} -> "Tool execution timed out after #{ms}ms"
          {name, ms} -> "Tool '#{name}' execution timed out after #{ms}ms"
        end

      %__MODULE__{
        message: message,
        tool_name: tool_name,
        timeout_ms: timeout_ms,
        details: details
      }
    end
  end

  defmodule ToolValidationFailed do
    @moduledoc """
    Error raised when tool parameters fail validation.
    """
    defexception [:message, :tool_name, :errors, :details]

    @impl true
    def exception(opts) do
      tool_name = Keyword.get(opts, :tool_name)
      errors = Keyword.get(opts, :errors)
      details = Keyword.get(opts, :details, %{})

      message =
        case {tool_name, errors} do
          {nil, nil} -> "Tool validation failed"
          {name, nil} -> "Tool '#{name}' validation failed"
          {nil, _} -> "Tool validation failed"
          {name, _} -> "Tool '#{name}' parameter validation failed"
        end

      %__MODULE__{
        message: message,
        tool_name: tool_name,
        errors: errors || [],
        details: details
      }
    end
  end
end
