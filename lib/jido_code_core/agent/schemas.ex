defmodule JidoCodeCore.Agent.Schemas do
  @moduledoc """
  Zoi schema definitions for JidoCodeCore agent state.

  This module defines the schemas used for validating and managing agent state,
  particularly for session agents that track conversation state, tool usage,
  and file operations.

  ## Session Agent Schema

  The `session_agent_schema/0` defines the complete structure of a session agent's state:

  ### Core Fields
  - `session_id` - Unique session identifier
  - `project_path` - Project root path
  - `language` - Primary programming language (default: `:elixir`)

  ### Conversation Fields
  - `messages` - Conversation messages with LLM
  - `reasoning_steps` - Chain-of-thought reasoning steps
  - `tool_calls` - Tool execution records
  - `todos` - Task tracking list

  ### File Tracking
  - `file_reads` - Map of files read during session
  - `file_writes` - Map of files written during session

  ### LLM Configuration
  - `llm_config` - LLM provider and model settings

  ## Usage

      # Validate session agent state
      {:ok, state} = Zoi.parse(session_agent_schema(), params)

      # Apply defaults to a partial state
      state = apply_defaults(%{session_id: "abc123"})

      # Validate and return error on failure
      case validate_session_agent(params) do
        {:ok, state} -> state
        {:error, errors} -> handle_errors(errors)
      end

  """

  @doc """
  Zoi schema for session agent state.

  Defines the complete structure of a session agent's state with all fields,
  default values, and validation rules.
  """
  @spec session_agent_schema() :: Zoi.schema()
  def session_agent_schema do
    Zoi.object(%{
      # ============================================================================
      # Core Session Fields
      # ============================================================================

      session_id:
        Zoi.string(description: "Unique session identifier")
        |> Zoi.optional(),

      project_path:
        Zoi.string(description: "Project root path")
        |> Zoi.optional(),

      language:
        Zoi.atom(description: "Primary programming language")
        |> Zoi.default(:elixir),

      # ============================================================================
      # Messages and Conversation
      # ============================================================================

      messages:
        Zoi.list(
          Zoi.any(),
          description: "Conversation messages with the LLM"
        )
        |> Zoi.default([]),

      reasoning_steps:
        Zoi.list(
          Zoi.any(),
          description: "Chain-of-thought reasoning steps"
        )
        |> Zoi.default([]),

      tool_calls:
        Zoi.list(
          Zoi.any(),
          description: "Tool call records"
        )
        |> Zoi.default([]),

      todos:
        Zoi.list(
          Zoi.any(),
          description: "Task tracking list"
        )
        |> Zoi.default([]),

      # ============================================================================
      # File Tracking
      # ============================================================================

      file_reads:
        Zoi.map(
          Zoi.string(),
          Zoi.any(),
          description: "Tracked file reads during session"
        )
        |> Zoi.default(%{}),

      file_writes:
        Zoi.map(
          Zoi.string(),
          Zoi.any(),
          description: "Tracked file writes during session"
        )
        |> Zoi.default(%{}),

      # ============================================================================
      # LLM Configuration
      # ============================================================================

      llm_config:
        Zoi.object(%{
          provider:
            Zoi.string(description: "LLM provider name")
            |> Zoi.default("anthropic"),

          model:
            Zoi.string(description: "LLM model identifier")
            |> Zoi.default("claude-3-5-sonnet-20241022"),

          temperature:
            Zoi.float(description: "Sampling temperature (0.0 - 1.0)")
            |> Zoi.default(0.7),

          max_tokens:
            Zoi.integer(description: "Maximum tokens to generate")
            |> Zoi.default(4096)
        })
        |> Zoi.default(%{}),

      # ============================================================================
      # Timestamps
      # ============================================================================

      created_at:
        Zoi.any(description: "Creation timestamp")
        |> Zoi.optional(),

      updated_at:
        Zoi.any(description: "Last update timestamp")
        |> Zoi.optional()
    })
  end

  @doc """
  Validates a map against the session agent schema.

  ## Parameters

  - `params` - A map containing session agent state data

  ## Returns

  - `{:ok, state}` - Valid state with defaults applied
  - `{:error, errors}` - Validation errors

  ## Examples

      iex> validate_session_agent(%{session_id: "abc123"})
      {:ok, %{session_id: "abc123", language: :elixir, messages: [], ...}}

      iex> validate_session_agent(%{temperature: "invalid"})
      {:error, [...]}
  """
  @spec validate_session_agent(map()) :: {:ok, map()} | {:error, term()}
  def validate_session_agent(params) when is_map(params) do
    # Parse with Zoi first to validate the structure
    case Zoi.parse(session_agent_schema(), params) do
      {:ok, state} ->
        # Post-process: ensure llm_config has all nested defaults
        {:ok, ensure_llm_nested_defaults(state)}

      {:error, error} ->
        {:error, format_zoi_error(error)}
    end
  end

  @doc """
  Applies default values from the session agent schema to a partial map.

  This is useful for creating new session agent states with sensible defaults
  without requiring full validation.

  ## Parameters

  - `params` - A map containing partial session agent state

  ## Returns

  - A map with all default values applied

  ## Examples

      iex> apply_defaults(%{session_id: "abc123"})
      %{session_id: "abc123", language: :elixir, messages: [], ...}
  """
  @spec apply_defaults(map()) :: map()
  def apply_defaults(params) when is_map(params) do
    # Parse with schema to apply top-level defaults
    case Zoi.parse(session_agent_schema(), params) do
      {:ok, state} -> ensure_llm_nested_defaults(state)
      {:error, _} -> params  # Return original params if validation fails
    end
  end

  @doc """
  Returns the default session agent state.

  ## Examples

      iex> default_state()
      %{language: :elixir, messages: [], reasoning_steps: [], ...}
  """
  @spec default_state() :: map()
  def default_state do
    apply_defaults(%{})
  end

  @doc """
  Returns the default LLM configuration.

  ## Examples

      iex> default_llm_config()
      %{provider: "anthropic", model: "claude-3-5-sonnet-20241022", temperature: 0.7, max_tokens: 4096}
  """
  @spec default_llm_config() :: map()
  def default_llm_config do
    %{
      provider: "anthropic",
      model: "claude-3-5-sonnet-20241022",
      temperature: 0.7,
      max_tokens: 4096
    }
  end

  # ============================================================================
  # Private Helpers
  # ============================================================================

  defp ensure_llm_nested_defaults(state) when is_map(state) do
    case Map.get(state, :llm_config) do
      nil ->
        # No llm_config, add default
        Map.put(state, :llm_config, default_llm_config())

      config when map_size(config) == 0 ->
        # Empty llm_config, add default
        Map.put(state, :llm_config, default_llm_config())

      config when is_map(config) ->
        # Partial llm_config, merge missing defaults (user values take precedence)
        # IMPORTANT: Map.merge(a, b) means b's values override a's values
        merged_config =
          Map.merge(default_llm_config(), config)

        Map.put(state, :llm_config, merged_config)

      _ ->
        state
    end
  end

  defp format_zoi_error(error) when is_struct(error) do
    # Handle Zoi error struct
    case Map.get(error, :__exception__, nil) do
      true -> Exception.message(error)
      nil -> inspect(error)
    end
  end

  defp format_zoi_error(error), do: error
end
