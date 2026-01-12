defmodule JidoCodeCore.API.Session do
  @moduledoc """
  Public API for session management in JidoCodeCore.

  This module provides the interface for creating, managing, and stopping
  work sessions (isolated project contexts). Sessions are the primary
  abstraction for managing conversations and state tied to specific projects.

  ## Session Lifecycle

  A session progresses through these states:

  1. **Created** - `start_session/1` creates a new session struct
  2. **Started** - Session supervisor and child processes are started
  3. **Running** - Session is active and can handle messages
  4. **Stopped** - `stop_session/1` terminates the session and cleans up

  ## Session Limits

  - Maximum concurrent sessions: 10 (configurable via `Application.put_env(:jido_code, :max_sessions, n)`)
  - Maximum messages per session: 1000
  - Maximum reasoning steps: 100
  - Maximum tool calls: 500

  ## Examples

      # Create and start a new session
      {:ok, session} = JidoCodeCore.API.Session.start_session(
        project_path: "/home/user/myproject",
        name: "My Project"
      )

      # List all active sessions
      sessions = JidoCodeCore.API.Session.list_sessions()

      # Get a specific session
      {:ok, session} = JidoCodeCore.API.Session.get_session("session-id")

      # Update session configuration
      {:ok, updated} = JidoCodeCore.API.Session.set_session_config(
        "session-id",
        %{temperature: 0.5, model: "claude-3-5-sonnet-20241022"}
      )

      # Stop a session
      :ok = JidoCodeCore.API.Session.stop_session("session-id")

  ## PubSub Events

  Session lifecycle events are broadcast on PubSub topics:

  - `JidoCodeCore.PubSubTopics.session_topic()` - Global session events
  - `JidoCodeCore.PubSubTopics.session_topic(session_id)` - Session-specific events

  Event types:
  - `{:session_started, session}` - Session successfully started
  - `{:session_stopped, session_id}` - Session stopped
  - `{:session_updated, session}` - Session configuration updated
  """

  alias JidoCodeCore.{Session, SessionSupervisor, SessionRegistry, Session.State}

  @typedoc "Session creation options"
  @type start_opts :: [
    project_path: Path.t(),
    name: String.t() | nil,
    config: map() | nil,
    supervisor_module: module() | nil
  ]

  @typedoc "Configuration update options"
  @type config_update :: %{
    optional(:provider) => atom(),
    optional(:model) => String.t(),
    optional(:temperature) => float(),
    optional(:max_tokens) => pos_integer()
  }

  @typedoc "Language atom or string"
  @type language :: atom() | String.t()

  # ============================================================================
  # Session Lifecycle
  # ============================================================================

  @doc """
  Starts a new session.

  Creates a session struct and starts its supervision tree. The session
  will be registered in the SessionRegistry and can be looked up by ID.

  ## Options

    - `:project_path` (required) - Absolute path to the project directory
    - `:name` (optional) - Display name for the session (defaults to folder name)
    - `:config` (optional) - LLM configuration map (provider, model, temperature, etc.)
    - `:supervisor_module` (optional) - Module to use as per-session supervisor
      (default: `JidoCodeCore.Session.Supervisor`, used for testing)

  ## Returns

    - `{:ok, session}` - Session created and started successfully
    - `{:error, :path_not_found}` - Project path doesn't exist
    - `{:error, :path_not_directory}` - Path exists but is not a directory
    - `{:error, {:session_limit_reached, current, max}}` - Maximum sessions reached
    - `{:error, :session_exists}` - Session with this ID already exists
    - `{:error, :project_already_open}` - Session for this project path exists

  ## Examples

      {:ok, session} = start_session(project_path: "/home/user/project")
      {:ok, session} = start_session(
        project_path: "/home/user/project",
        name: "My Project",
        config: %{temperature: 0.7, model: "claude-3-5-sonnet-20241022"}
      )

  """
  @spec start_session(start_opts()) :: {:ok, Session.t()} | {:error, term()}
  def start_session(opts) when is_list(opts) do
    with {:ok, session} <- Session.new(opts),
         {:ok, _pid} <- SessionSupervisor.start_session(session) do
      {:ok, session}
    end
  end

  @doc """
  Stops a session by its ID.

  Terminates the session's supervision tree and unregisters it from the
  SessionRegistry. Session state is saved to disk before stopping.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - `:ok` - Session stopped successfully
    - `{:error, :not_found}` - No session with this ID exists

  ## Examples

      :ok = stop_session("session-id")

  """
  @spec stop_session(String.t()) :: :ok | {:error, :not_found}
  def stop_session(session_id) when is_binary(session_id) do
    SessionSupervisor.stop_session(session_id)
  end

  # ============================================================================
  # Session Query
  # ============================================================================

  @doc """
  Lists all active sessions.

  Returns sessions sorted by `created_at` timestamp (oldest first).

  ## Returns

    - List of `Session.t()` structs for all registered sessions

  ## Examples

      sessions = list_sessions()
      length(sessions)
      # => 3

  """
  @spec list_sessions() :: [Session.t()]
  def list_sessions do
    SessionRegistry.list_all()
  end

  @doc """
  Gets a session by its ID.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - `{:ok, session}` - Session found
    - `{:error, :not_found}` - No session with this ID

  ## Examples

      {:ok, session} = get_session("session-id")
      session.name
      # => "My Project"

  """
  @spec get_session(String.t()) :: {:ok, Session.t()} | {:error, :not_found}
  def get_session(session_id) when is_binary(session_id) do
    SessionRegistry.lookup(session_id)
  end

  @doc """
  Gets a session by project path.

  ## Parameters

    - `project_path` - The absolute path to the project directory

  ## Returns

    - `{:ok, session}` - Session found
    - `{:error, :not_found}` - No session for this path

  ## Examples

      {:ok, session} = get_session_by_path("/home/user/project")

  """
  @spec get_session_by_path(Path.t()) :: {:ok, Session.t()} | {:error, :not_found}
  def get_session_by_path(project_path) when is_binary(project_path) do
    SessionRegistry.lookup_by_path(project_path)
  end

  @doc """
  Checks if a session is currently running.

  A session is running if its supervisor process is alive.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - `true` - Session is running
    - `false` - Session not found or process is dead

  ## Examples

      session_running?("session-id")
      # => true

  """
  @spec session_running?(String.t()) :: boolean()
  def session_running?(session_id) when is_binary(session_id) do
    SessionSupervisor.session_running?(session_id)
  end

  # ============================================================================
  # Session Configuration
  # ============================================================================

  @doc """
  Updates the session's LLM configuration.

  Merges the provided config with the existing session config.

  ## Parameters

    - `session_id` - The session's unique ID
    - `config` - Map of config options to merge

  ## Config Options

    - `:provider` - LLM provider (`:anthropic`, `:openai`, etc.)
    - `:model` - Model identifier string
    - `:temperature` - Sampling temperature (0.0 to 1.0)
    - `:max_tokens` - Maximum tokens in response

  ## Returns

    - `{:ok, session}` - Configuration updated successfully
    - `{:error, :not_found}` - Session not found
    - `{:error, reasons}` - Config validation errors

  ## Examples

      {:ok, session} = set_session_config("session-id", %{
        temperature: 0.5,
        model: "claude-3-5-sonnet-20241022"
      })

  """
  @spec set_session_config(String.t(), config_update()) ::
          {:ok, Session.t()} | {:error, :not_found | [atom()]}
  def set_session_config(session_id, config)
      when is_binary(session_id) and is_map(config) do
    State.update_session_config(session_id, config)
  end

  @doc """
  Sets the session's programming language.

  ## Parameters

    - `session_id` - The session's unique ID
    - `language` - Language atom, string, or alias

  ## Supported Languages

  - `:elixir`, `"elixir"`, `"ex"`
  - `:python`, `"python"`, `"py"`
  - `:javascript`, `"javascript"`, `"js"`
  - `:typescript`, `"typescript"`, `"ts"`
  - `:rust`, `"rust"`, `"rs"`
  - `:go`, `"go"`
  - `:java`, `"java"`
  - `:cpp`, `"cpp"`, `"c++"`
  - `:c`, `"c"`
  - And more - see `JidoCodeCore.Language` for complete list

  ## Returns

    - `{:ok, session}` - Language updated successfully
    - `{:error, :not_found}` - Session not found
    - `{:error, :invalid_language}` - Language is not supported

  ## Examples

      {:ok, session} = set_session_language("session-id", :python)
      {:ok, session} = set_session_language("session-id", "js")  # Alias

  """
  @spec set_session_language(String.t(), language()) ::
          {:ok, Session.t()} | {:error, :not_found | :invalid_language}
  def set_session_language(session_id, language) when is_binary(session_id) do
    State.update_language(session_id, language)
  end

  @doc """
  Renames a session.

  ## Parameters

    - `session_id` - The session's unique ID
    - `new_name` - New display name for the session

  ## Returns

    - `{:ok, session}` - Session renamed successfully
    - `{:error, :not_found}` - Session not found

  ## Examples

      {:ok, session} = rename_session("session-id", "New Name")

  """
  @spec rename_session(String.t(), String.t()) ::
          {:ok, Session.t()} | {:error, :not_found}
  def rename_session(session_id, new_name)
      when is_binary(session_id) and is_binary(new_name) do
    with {:ok, session} <- get_session(session_id),
         {:ok, renamed} <- Session.rename(session, new_name),
         {:ok, _} <- SessionRegistry.update(renamed) do
      {:ok, renamed}
    end
  end

  # ============================================================================
  # Session State Access
  # ============================================================================

  @doc """
  Gets the current state for a session.

  Returns the full runtime state including messages, reasoning steps,
  tool calls, and todos.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - `{:ok, state}` - Full session state map
    - `{:error, :not_found}` - Session not found

  ## Examples

      {:ok, state} = get_session_state("session-id")
      state.messages
      # => [%{id: "1", role: :user, content: "..."}, ...]

  """
  @spec get_session_state(String.t()) ::
          {:ok, State.state()} | {:error, :not_found}
  def get_session_state(session_id) when is_binary(session_id) do
    State.get_state(session_id)
  end

  @doc """
  Gets the messages for a session.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - `{:ok, messages}` - List of messages in chronological order
    - `{:error, :not_found}` - Session not found

  ## Examples

      {:ok, messages} = get_messages("session-id")

  """
  @spec get_messages(String.t()) ::
          {:ok, [State.message()]} | {:error, :not_found}
  def get_messages(session_id) when is_binary(session_id) do
    State.get_messages(session_id)
  end

  @doc """
  Gets paginated messages for a session.

  More efficient than `get_messages/1` for large conversation histories.

  ## Parameters

    - `session_id` - The session's unique ID
    - `offset` - Number of messages to skip from the start
    - `limit` - Maximum number of messages to return (or `:all` for no limit)

  ## Returns

    - `{:ok, messages, metadata}` - Messages with pagination info
    - `{:error, :not_found}` - Session not found

  ## Metadata

    - `:total` - Total number of messages
    - `:offset` - The offset used
    - `:limit` - The limit used
    - `:returned` - Number of messages returned
    - `:has_more` - Whether there are more messages

  ## Examples

      {:ok, messages, meta} = get_messages("session-id", 0, 10)
      meta.has_more
      # => true

  """
  @spec get_messages(String.t(), non_neg_integer(), pos_integer() | :all) ::
          {:ok, [State.message()], map()} | {:error, :not_found}
  def get_messages(session_id, offset, limit)
      when is_binary(session_id) and is_integer(offset) and offset >= 0 do
    State.get_messages(session_id, offset, limit)
  end

  @doc """
  Gets the reasoning steps for a session.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - `{:ok, steps}` - List of reasoning steps
    - `{:error, :not_found}` - Session not found

  ## Examples

      {:ok, steps} = get_reasoning_steps("session-id")

  """
  @spec get_reasoning_steps(String.t()) ::
          {:ok, [State.reasoning_step()]} | {:error, :not_found}
  def get_reasoning_steps(session_id) when is_binary(session_id) do
    State.get_reasoning_steps(session_id)
  end

  @doc """
  Gets the todo list for a session.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - `{:ok, todos}` - List of todo items
    - `{:error, :not_found}` - Session not found

  ## Examples

      {:ok, todos} = get_todos("session-id")

  """
  @spec get_todos(String.t()) :: {:ok, [State.todo()]} | {:error, :not_found}
  def get_todos(session_id) when is_binary(session_id) do
    State.get_todos(session_id)
  end
end
