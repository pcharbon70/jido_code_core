defmodule JidoCodeCore.Errors.Validation do
  @moduledoc """
  Validation-related errors.

  ## Error Types

  - `InvalidParameters` - Input parameters are invalid
  - `SchemaValidationFailed` - Schema validation failed
  - `InvalidSessionId` - Session ID format is invalid

  ## Examples

      raise Errors.Validation.InvalidParameters.exception(
        field: :path,
        value: nil,
        message: "path is required"
      )

      raise Errors.Validation.SchemaValidationFailed.exception(
        schema: "ToolParams",
        errors: [%{path: [:path], message: "is required"}]
      )

      raise Errors.Validation.InvalidSessionId.exception(
        session_id: "not-a-uuid",
        reason: "invalid_format"
      )
  """

  defmodule InvalidParameters do
    @moduledoc """
    Error raised when input parameters are invalid.
    """
    defexception [:message, :field, :value, :params, :details]

    @impl true
    def exception(opts) do
      field = Keyword.get(opts, :field)
      value = Keyword.get(opts, :value)
      params = Keyword.get(opts, :params)
      message = Keyword.get(opts, :message)
      details = Keyword.get(opts, :details, %{})

      error_message =
        cond do
          message != nil ->
            message

          field != nil and value != nil ->
            "Invalid value for field '#{inspect(field)}': #{inspect(value)}"

          field != nil ->
            "Invalid value for field '#{inspect(field)}'"

          params != nil ->
            "Invalid parameters: #{inspect(params)}"

          true ->
            "Invalid parameters"
        end

      %__MODULE__{
        message: error_message,
        field: field,
        value: value,
        params: params,
        details: details
      }
    end
  end

  defmodule SchemaValidationFailed do
    @moduledoc """
    Error raised when schema validation fails.
    """
    defexception [:message, :schema, :errors, :subject, :details]

    @impl true
    def exception(opts) do
      schema = Keyword.get(opts, :schema)
      errors = Keyword.get(opts, :errors)
      subject = Keyword.get(opts, :subject)
      details = Keyword.get(opts, :details, %{})

      message =
        case schema do
          nil -> "Schema validation failed"
          s when is_binary(s) -> "Schema validation failed for '#{s}'"
          s when is_atom(s) -> "Schema validation failed for #{inspect(s)}"
        end

      %__MODULE__{
        message: message,
        schema: schema,
        errors: errors || [],
        subject: subject,
        details: details
      }
    end
  end

  defmodule InvalidSessionId do
    @moduledoc """
    Error raised when a session ID format is invalid.
    """
    defexception [:message, :session_id, :reason, :details]

    @impl true
    def exception(opts) do
      session_id = Keyword.get(opts, :session_id)
      reason = Keyword.get(opts, :reason)
      details = Keyword.get(opts, :details, %{})

      message =
        case {session_id, reason} do
          {nil, nil} -> "Invalid session ID"
          {id, nil} -> "Invalid session ID: '#{id}'"
          {nil, r} -> "Invalid session ID: #{inspect(r)}"
          {id, _} -> "Invalid session ID: '#{id}'"
        end

      %__MODULE__{
        message: message,
        session_id: session_id,
        reason: reason,
        details: details
      }
    end
  end
end
