defmodule JidoCodeCore.Errors.Session do
  @moduledoc """
  Session-related errors.

  ## Error Types

  - `SessionNotFound` - Session does not exist or is not registered
  - `SessionInvalidState` - Session is in an invalid state for the requested operation
  - `SessionConfigError` - Session configuration is invalid or missing

  ## Examples

      raise Errors.Session.SessionNotFound.exception(session_id: "abc123")

      raise Errors.Session.SessionInvalidState.exception(
        session_id: "abc123",
        current_state: :stopped,
        required_state: :running
      )

      raise Errors.Session.SessionConfigError.exception(
        missing_key: :model,
        config: %{provider: "openai"}
      )
  """

  defmodule SessionNotFound do
    @moduledoc """
    Error raised when a session is not found in the registry.
    """
    defexception [:message, :session_id, :details]

    @impl true
    def exception(opts) do
      session_id = Keyword.get(opts, :session_id)
      details = Keyword.get(opts, :details, %{})

      message =
        case session_id do
          nil -> "Session not found"
          id when is_binary(id) -> "Session '#{id}' not found"
        end

      %__MODULE__{
        message: message,
        session_id: session_id,
        details: details
      }
    end
  end

  defmodule SessionInvalidState do
    @moduledoc """
    Error raised when a session is in an invalid state for the requested operation.
    """
    defexception [:message, :session_id, :current_state, :required_state, :details]

    @impl true
    def exception(opts) do
      session_id = Keyword.get(opts, :session_id)
      current_state = Keyword.get(opts, :current_state)
      required_state = Keyword.get(opts, :required_state)
      details = Keyword.get(opts, :details, %{})

      message =
        case {session_id, current_state, required_state} do
          {nil, current, required} ->
            "Session is in invalid state: #{inspect(current)} (requires: #{inspect(required)})"

          {id, current, required} ->
            "Session '#{id}' is in invalid state: #{inspect(current)} (requires: #{inspect(required)})"
        end

      %__MODULE__{
        message: message,
        session_id: session_id,
        current_state: current_state,
        required_state: required_state,
        details: details
      }
    end
  end

  defmodule SessionConfigError do
    @moduledoc """
    Error raised when session configuration is invalid or missing required values.
    """
    defexception [:message, :missing_key, :invalid_key, :config, :details]

    @impl true
    def exception(opts) do
      missing_key = Keyword.get(opts, :missing_key)
      invalid_key = Keyword.get(opts, :invalid_key)
      config = Keyword.get(opts, :config)
      details = Keyword.get(opts, :details, %{})

      message =
        cond do
          missing_key ->
            "Session configuration missing required key: #{inspect(missing_key)}"

          invalid_key ->
            "Session configuration has invalid value for: #{inspect(invalid_key)}"

          true ->
            "Session configuration error"
        end

      %__MODULE__{
        message: message,
        missing_key: missing_key,
        invalid_key: invalid_key,
        config: config,
        details: details
      }
    end
  end
end
