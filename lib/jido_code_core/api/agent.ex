defmodule JidoCodeCore.API.Agent do
  @moduledoc """
  Public API for agent interaction in JidoCodeCore.Core.

  This module provides the interface for sending messages to LLM agents,
  managing agent lifecycle, and handling streaming responses.

  ## Agent Communication Pattern

  Agents communicate via two patterns:

  1. **Request/Response** - `send_message/3` for synchronous responses
  2. **Streaming** - `send_message_stream/3` for real-time streaming via PubSub

  ## PubSub Events

  All agent events are broadcast to session-specific PubSub topics:

  - `JidoCodeCore.Core.PubSubTopics.agent_topic(session_id)` - Session-specific events

  Event types:
  - `{:stream_chunk, content}` - Partial response content (streaming)
  - `{:stream_end, full_content}` - Stream completed
  - `{:stream_error, reason}` - Stream failed
  - `{:agent_response, response}` - Full response (non-streaming)
  - `{:reasoning_step, step}` - Chain-of-thought reasoning update
  - `{:tool_call, name, args, id}` - Tool execution started
  - `{:tool_result, result}` - Tool execution completed
  - `{:agent_status, status}` - Agent status changed

  ## Examples

      # Send a message and get response
      {:ok, response} = JidoCodeCore.API.Agent.send_message(
        "session-id",
        "How do I reverse a list in Elixir?"
      )

      # Send with streaming
      :ok = JidoCodeCore.API.Agent.send_message_stream(
        "session-id",
        "Explain GenServer"
      )
      # Subscribe to PubSub to receive {:stream_chunk, content} events

      # Get agent status
      {:ok, status} = JidoCodeCore.API.Agent.get_status("session-id")
      status.ready
      # => true

  """

  alias JidoCodeCore.Agents.LLMAgent
  alias JidoCodeCore.Session.ProcessRegistry

  @typedoc "Message options"
  @type message_opts :: [
    timeout: pos_integer(),
    system_prompt: String.t() | nil
  ]

  @typedoc "Agent status"
  @type agent_status :: %{
    ready: boolean(),
    config: map(),
    session_id: String.t() | nil,
    topic: String.t() | nil
  }

  # ============================================================================
  # Message Sending
  # ============================================================================

  @doc """
  Sends a message to the agent and returns the response.

  This is a synchronous call that waits for the complete LLM response.

  ## Parameters

    - `session_id` - The session's unique ID
    - `message` - The user's message (max 10,000 characters)
    - `opts` - Optional keyword list

  ## Options

    - `:timeout` - Request timeout in milliseconds (default: 60,000)
    - `:system_prompt` - Override system prompt (advanced use)

  ## Returns

    - `{:ok, response}` - LLM response string
    - `{:error, :not_found}` - Agent not found for this session
    - `{:error, :message_too_long}` - Message exceeds 10,000 characters
    - `{:error, reason}` - Other failures

  ## Examples

      {:ok, response} = send_message("session-id", "Explain pattern matching")
      {:ok, response} = send_message("session-id", "What is a GenServer?", timeout: 120_000)

  """
  @spec send_message(String.t(), String.t(), message_opts()) ::
          {:ok, String.t()} | {:error, term()}
  def send_message(session_id, message, opts \\ [])
      when is_binary(session_id) and is_binary(message) and is_list(opts) do
    with {:ok, pid} <- find_agent(session_id),
         {:ok, response} <- LLMAgent.chat(pid, message, opts) do
      {:ok, response}
    end
  end

  @doc """
  Sends a message to the agent with streaming response.

  Unlike `send_message/3`, this returns immediately and broadcasts
  response chunks via PubSub as they arrive.

  ## PubSub Events

  Subscribe to `JidoCodeCore.Core.PubSubTopics.agent_topic(session_id)` to receive:

  - `{:stream_chunk, content}` - Partial response text
  - `{:stream_end, full_content}` - Stream completed
  - `{:stream_error, reason}` - Stream failed

  ## Parameters

    - `session_id` - The session's unique ID
    - `message` - The user's message (max 10,000 characters)
    - `opts` - Optional keyword list

  ## Options

    - `:timeout` - Request timeout in milliseconds (default: 60,000)

  ## Returns

    - `:ok` - Stream started successfully
    - `{:error, :not_found}` - Agent not found for this session
    - `{:error, :message_too_long}` - Message exceeds 10,000 characters

  ## Examples

      :ok = send_message_stream("session-id", "Explain Elixir processes")

      # Subscribe to receive chunks
      topic = JidoCodeCore.Core.PubSubTopics.agent_topic("session-id")
      Phoenix.PubSub.subscribe(JidoCodeCore.PubSub, topic)

      receive do
        {:stream_chunk, content} -> IO.write(content)
        {:stream_end, _content} -> :done
      end

  """
  @spec send_message_stream(String.t(), String.t(), message_opts()) :: :ok | {:error, term()}
  def send_message_stream(session_id, message, opts \\ [])
      when is_binary(session_id) and is_binary(message) and is_list(opts) do
    with {:ok, pid} <- find_agent(session_id),
         :ok <- LLMAgent.chat_stream(pid, message, opts) do
      :ok
    end
  end

  # ============================================================================
  # Agent Status and Configuration
  # ============================================================================

  @doc """
  Gets the current status of the session's agent.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - `{:ok, status}` - Status map with:
      - `:ready` - Boolean indicating if agent is ready
      - `:config` - Current LLM configuration
      - `:session_id` - Session identifier
      - `:topic` - PubSub topic for this agent
    - `{:error, :not_found}` - Agent not found for this session

  ## Examples

      {:ok, status} = get_status("session-id")
      if status.ready do
        send_message("session-id", "Hello!")
      end

  """
  @spec get_status(String.t()) :: {:ok, agent_status()} | {:error, :not_found}
  def get_status(session_id) when is_binary(session_id) do
    with {:ok, pid} <- find_agent(session_id),
         {:ok, status} <- LLMAgent.get_status(pid) do
      {:ok, status}
    end
  end

  @doc """
  Gets the current LLM configuration for the session's agent.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - `{:ok, config}` - Configuration map with provider, model, temperature, etc.
    - `{:error, :not_found}` - Agent not found for this session

  ## Examples

      {:ok, config} = get_agent_config("session-id")
      config.model
      # => "claude-3-5-sonnet-20241022"

  """
  @spec get_agent_config(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_agent_config(session_id) when is_binary(session_id) do
    with {:ok, pid} <- find_agent(session_id),
         config when is_map(config) <- LLMAgent.get_config(pid) do
      {:ok, config}
    end
  end

  @doc """
  Reconfigures the agent with new provider/model settings.

  Performs hot-swapping of the LLM configuration without restarting
  the agent process.

  ## Parameters

    - `session_id` - The session's unique ID
    - `opts` - Configuration options

  ## Options

    - `:provider` - New provider atom (`:anthropic`, `:openai`, etc.)
    - `:model` - New model name string
    - `:temperature` - New temperature (0.0-1.0)
    - `:max_tokens` - New max tokens

  ## Returns

    - `:ok` - Configuration updated
    - `{:error, :not_found}` - Agent not found for this session
    - `{:error, reason}` - Validation failed

  ## Examples

      :ok = reconfigure_agent("session-id", provider: :openai, model: "gpt-4o")

  """
  @spec reconfigure_agent(String.t(), keyword()) :: :ok | {:error, term()}
  def reconfigure_agent(session_id, opts) when is_binary(session_id) and is_list(opts) do
    with {:ok, pid} <- find_agent(session_id),
         :ok <- LLMAgent.configure(pid, opts) do
      :ok
    end
  end

  # ============================================================================
  # Tool Execution via Agent
  # ============================================================================

  @doc """
  Executes a tool call using the agent's session context.

  The tool is executed with proper path validation and security boundaries
  enforced by the session's tool executor.

  ## Parameters

    - `session_id` - The session's unique ID
    - `tool_call` - Map with `:id`, `:name`, `:arguments` keys

  ## Returns

    - `{:ok, result}` - Tool execution result
    - `{:error, :not_found}` - Agent or session not found
    - `{:error, reason}` - Execution failed

  ## Examples

      tool_call = %{
        id: "call_1",
        name: "read_file",
        arguments: %{"path" => "/src/main.ex"}
      }
      {:ok, result} = execute_tool_via_agent("session-id", tool_call)

  """
  @spec execute_tool_via_agent(String.t(), map()) :: {:ok, term()} | {:error, term()}
  def execute_tool_via_agent(session_id, tool_call)
      when is_binary(session_id) and is_map(tool_call) do
    with {:ok, pid} <- find_agent(session_id),
         {:ok, result} <- LLMAgent.execute_tool(pid, tool_call) do
      {:ok, result}
    end
  end

  @doc """
  Executes multiple tool calls in batch using the agent's session context.

  ## Parameters

    - `session_id` - The session's unique ID
    - `tool_calls` - List of tool call maps
    - `opts` - Options

  ## Options

    - `:parallel` - Execute tools in parallel (default: `false`)
    - `:timeout` - Override timeout per tool

  ## Returns

    - `{:ok, results}` - List of results
    - `{:error, :not_found}` - Agent or session not found
    - `{:error, reason}` - Execution failed

  ## Examples

      tool_calls = [
        %{id: "1", name: "read_file", arguments: %{"path" => "/a.txt"}},
        %{id: "2", name: "read_file", arguments: %{"path" => "/b.txt"}}
      ]
      {:ok, results} = execute_tools_batch("session-id", tool_calls, parallel: true)

  """
  @spec execute_tools_batch(String.t(), [map()], keyword()) ::
          {:ok, [term()]} | {:error, term()}
  def execute_tools_batch(session_id, tool_calls, opts \\ [])
      when is_binary(session_id) and is_list(tool_calls) do
    with {:ok, pid} <- find_agent(session_id),
         {:ok, results} <- LLMAgent.execute_tool_batch(pid, tool_calls, opts) do
      {:ok, results}
    end
  end

  # ============================================================================
  # PubSub Topic Helpers
  # ============================================================================

  @doc """
  Gets the PubSub topic for a session's agent events.

  Use this to subscribe to agent events for a specific session.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - PubSub topic string for the session

  ## Examples

      topic = agent_topic("session-id")
      Phoenix.PubSub.subscribe(JidoCodeCore.PubSub, topic)

  """
  @spec agent_topic(String.t()) :: String.t()
  def agent_topic(session_id) when is_binary(session_id) do
    LLMAgent.topic_for_session(session_id)
  end

  @doc """
  Lists available LLM providers.

  ## Returns

    - `{:ok, providers}` - List of provider atoms
    - `{:error, reason}` - Registry unavailable

  ## Examples

      {:ok, providers} = list_providers()
      # => {:ok, [:anthropic, :openai, :google, ...]}

  """
  @spec list_providers() :: {:ok, [atom()]} | {:error, term()}
  def list_providers do
    LLMAgent.list_providers()
  end

  # ============================================================================
  # Private Helpers
  # ============================================================================

  @spec find_agent(String.t()) :: {:ok, pid()} | {:error, :not_found}
  defp find_agent(session_id) do
    ProcessRegistry.lookup(:agent, session_id)
  end
end
