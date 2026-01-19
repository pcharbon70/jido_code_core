defmodule JidoCodeCore.Errors do
  @moduledoc """
  Unified error handling for JidoCodeCore using Splode.

  ## Error Classes

  Five error class categories cover all failure scenarios:

  | Error Class | Use Case |
  |-------------|----------|
  | `Session` | Session lifecycle, state, and configuration errors |
  | `Tools` | Tool discovery, execution, and validation errors |
  | `Memory` | Memory storage, retrieval, and promotion errors |
  | `Validation` | Input, parameter, and schema validation errors |
  | `Agent` | Agent lifecycle and runtime errors |

  ## Usage

      # Session errors
      raise Errors.Session.SessionNotFound.exception(session_id: "abc123")

      # Tools errors
      raise Errors.Tools.ToolNotFound.exception(tool_name: "read_file")

      # Memory errors
      raise Errors.Memory.MemoryStorageFailed.exception(reason: "disk full")

      # Validation errors
      raise Errors.Validation.InvalidParameters.exception(params: %{path: "invalid"})

      # Agent errors
      raise Errors.Agent.AgentNotRunning.exception(agent_id: "agent-1")

  ## Error Fields

  All error structs support:
  - `message` - Human-readable error message
  - `details` - Additional context map
  - Specific fields per error type (see individual error modules)
  """

  # ============================================================================
  # Splode Configuration
  # ============================================================================

  use Splode,
    error_classes: [
      session: JidoCodeCore.Errors.Session,
      tools: JidoCodeCore.Errors.Tools,
      memory: JidoCodeCore.Errors.Memory,
      validation: JidoCodeCore.Errors.Validation,
      agent: JidoCodeCore.Errors.Agent
    ],
    unknown_error: JidoCodeCore.Errors.Validation.InvalidParameters

  # ============================================================================
  # Public API
  # ============================================================================

  @doc """
  Normalizes an error term into a Splode error.

  Handles various error formats and converts them to appropriate
  JidoCodeCore.Errors exceptions.

  ## Examples

      iex> Errors.normalize({:error, :not_found})
      iex> Errors.normalize("some error")
      iex> Errors.normalize(%RuntimeError{})
  """
  @spec normalize(term()) :: Exception.t()
  def normalize({:error, reason}), do: normalize(reason)
  def normalize(reason) when is_binary(reason), do: JidoCodeCore.Errors.Validation.InvalidParameters.exception(message: reason)
  def normalize(reason) when is_atom(reason), do: JidoCodeCore.Errors.Validation.InvalidParameters.exception(message: Atom.to_string(reason))
  def normalize(%_{} = error), do: error
  def normalize(_), do: JidoCodeCore.Errors.Validation.InvalidParameters.exception(message: "Unknown error")

  @doc """
  Converts an error to a human-readable message string.
  """
  @spec message(Exception.t()) :: String.t()
  def message(%{message: msg}) when is_binary(msg), do: msg
  def message(%{message: %_{message: inner}}), do: message(inner)
  def message(error), do: Exception.message(error)
end
