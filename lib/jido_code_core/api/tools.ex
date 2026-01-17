defmodule JidoCodeCore.API.Tools do
  @moduledoc """
  Public API for tool system queries and execution in JidoCodeCore.Core.

  This module provides the interface for:
  - Listing and querying available tools
  - Getting tool schemas and definitions
  - Executing tools directly with proper context

  ## Tool System Overview

  Tools are units of functionality that the agent can call. Each tool has:
  - A unique name (e.g., `"read_file"`, `"grep"`)
  - A description for the LLM
  - A parameter schema defining required/optional arguments
  - A handler module that implements the tool logic

  ## Tool Categories

  - **File System** - `read_file`, `write_file`, `edit_file`, `list_directory`, `create_directory`, `delete_file`, `file_info`
  - **Search** - `grep`, `find_files`
  - **Shell** - `run_command`
  - **Web** - `web_fetch`, `web_search`
  - **Memory** - `remember`, `recall`, `forget`
  - **Livebook** - `livebook_edit`
  - **Task** - `spawn_task`, `todo_write`

  ## Examples

      # List all available tools
      tools = list_tools()

      # Get a specific tool's schema
      {:ok, tool} = get_tool_schema("read_file")

      # Execute a tool directly
      {:ok, result} = execute_tool(
        "session-id",
        "read_file",
        %{"path" => "/src/main.ex"}
      )

      # Execute with custom timeout
      {:ok, result} = execute_tool(
        "session-id",
        "grep",
        %{"pattern" => "def", "path" => "/lib"},
        timeout: 60_000
      )

  """

  alias JidoCodeCore.Tools.{Executor, Registry, Result, Tool}

  @typedoc "Tool execution options"
  @type execute_opts :: [
          timeout: pos_integer(),
          project_root: Path.t()
        ]

  @typedoc "Tool execution result"
  @type tool_result :: %Result{
          tool_call_id: String.t(),
          tool_name: String.t(),
          status: :ok | :error | :timeout,
          content: String.t(),
          duration_ms: non_neg_integer()
        }

  # ============================================================================
  # Tool Listing and Query
  # ============================================================================

  @doc """
  Lists all registered tools.

  Returns tools sorted alphabetically by name.

  ## Returns

    - List of `%Tool{}` structs with name, description, and parameters

  ## Examples

      tools = list_tools()
      # => [
      #   %Tool{name: "create_directory", description: "...", parameters: [...]},
      #   %Tool{name: "delete_file", description: "...", parameters: [...]},
      #   %Tool{name: "edit_file", description: "...", parameters: [...]},
      #   ...
      # ]

  """
  @spec list_tools() :: [Tool.t()]
  def list_tools do
    Registry.list()
  end

  @doc """
  Gets a tool's schema by name.

  ## Parameters

    - `name` - The tool name

  ## Returns

    - `{:ok, tool}` - Tool struct with full schema
    - `{:error, :not_found}` - Tool not registered

  ## Examples

      {:ok, tool} = get_tool_schema("read_file")
      tool.name
      # => "read_file"
      tool.parameters
      # => [%Parameter{name: "path", type: "string", required: true, ...}]

  """
  @spec get_tool_schema(String.t()) :: {:ok, Tool.t()} | {:error, :not_found}
  def get_tool_schema(name) when is_binary(name) do
    Registry.get(name)
  end

  @doc """
  Checks if a tool is registered.

  ## Parameters

    - `name` - The tool name

  ## Returns

    - `true` - Tool is registered
    - `false` - Tool is not registered

  ## Examples

      tool_registered?("read_file")
      # => true

      tool_registered?("unknown_tool")
      # => false

  """
  @spec tool_registered?(String.t()) :: boolean()
  def tool_registered?(name) when is_binary(name) do
    Registry.registered?(name)
  end

  @doc """
  Returns the count of registered tools.

  ## Examples

      count_tools()
      # => 15

  """
  @spec count_tools() :: non_neg_integer()
  def count_tools do
    Registry.count()
  end

  # ============================================================================
  # Tool Execution
  # ============================================================================

  @doc """
  Executes a tool by name with arguments.

  This is the primary interface for executing tools outside of the
  agent's tool-calling flow. The tool is executed with proper
  path validation, security enforcement, and PubSub event broadcasting.

  ## Parameters

    - `session_id` - The session's unique ID (used for security context)
    - `tool_name` - Name of the tool to execute
    - `arguments` - Map of argument names to values
    - `opts` - Optional execution options

  ## Options

    - `:timeout` - Execution timeout in milliseconds (default: 30,000)
    - `:project_root` - Override project root path (default: from session)

  ## Returns

    - `{:ok, result}` - `%Result{}` struct with execution outcome
    - `{:error, :tool_not_found}` - Tool not registered
    - `{:error, :invalid_arguments}` - Arguments don't match schema
    - `{:error, reason}` - Other execution failures

  ## Examples

      {:ok, result} = execute_tool("session-id", "read_file", %{
        "path" => "/src/main.ex"
      })
      result.status
      # => :ok
      result.content
      # => "defmodule MyApp do..."

  """
  @spec execute_tool(String.t(), String.t(), map(), execute_opts()) ::
          {:ok, tool_result()} | {:error, term()}
  def execute_tool(session_id, tool_name, arguments, opts \\ [])
      when is_binary(session_id) and is_binary(tool_name) and is_map(arguments) do
    with {:ok, context} <- build_execution_context(session_id, opts),
         {:ok, tool} <- Registry.get(tool_name) do
      tool_call = %{
        id: generate_call_id(),
        name: tool_name,
        arguments: arguments
      }

      Executor.execute(tool_call, context: context, timeout: Keyword.get(opts, :timeout))
    end
  end

  @doc """
  Executes multiple tools in batch.

  Tools are executed sequentially by default. Use `parallel: true` option
  for concurrent execution.

  ## Parameters

    - `session_id` - The session's unique ID
    - `tool_calls` - List of maps with `:name` and `:arguments` keys
    - `opts` - Optional execution options

  ## Options

    - `:parallel` - Execute tools concurrently (default: `false`)
    - `:timeout` - Per-tool timeout in milliseconds (default: 30,000)
    - `:project_root` - Override project root path

  ## Returns

    - `{:ok, results}` - List of `%Result{}` structs
    - `{:error, reason}` - Execution failed

  ## Examples

      tool_calls = [
        %{name: "read_file", arguments: %{"path" => "/a.txt"}},
        %{name: "read_file", arguments: %{"path" => "/b.txt"}}
      ]
      {:ok, results} = execute_tools("session-id", tool_calls, parallel: true)

  """
  @spec execute_tools(String.t(), [map()], execute_opts()) ::
          {:ok, [tool_result()]} | {:error, term()}
  def execute_tools(session_id, tool_calls, opts \\ [])
      when is_binary(session_id) and is_list(tool_calls) do
    with {:ok, context} <- build_execution_context(session_id, opts) do
      # Add IDs to tool calls if missing
      calls =
        Enum.map(tool_calls, fn call ->
          Map.put_new(call, :id, generate_call_id())
        end)

      Executor.execute_batch(calls, context: context, timeout: Keyword.get(opts, :timeout))
    end
  end

  # ============================================================================
  # LLM Integration
  # ============================================================================

  @doc """
  Gets all tools in LLM-compatible format.

  Returns a list of function definitions suitable for inclusion in an
  OpenAI-compatible chat completion request's `tools` parameter.

  ## Returns

    - List of maps with `type: "function"` and `function` keys

  ## Examples

      functions = tools_for_llm()
      # Use in API call:
      # completion = OpenAI.chat_completion(messages, tools: functions)

  """
  @spec tools_for_llm() :: [map()]
  def tools_for_llm do
    Registry.to_llm_format()
  end

  @doc """
  Gets a text description of all tools.

  Creates a human-readable summary for models that don't support
  function calling or for inclusion in system prompts.

  ## Returns

    - Formatted string describing all available tools

  ## Examples

      description = describe_tools()
      # => "## read_file
      # Reads a file...
      #
      # ## grep
      # Searches file contents...
      # ..."

  """
  @spec describe_tools() :: String.t()
  def describe_tools do
    Registry.to_text_description()
  end

  @doc """
  Parses tool calls from an LLM response.

  Extracts tool calls from OpenAI-format responses containing
  a "tool_calls" key.

  ## Parameters

    - `llm_response` - Response map from LLM API

  ## Returns

    - `{:ok, tool_calls}` - List of parsed tool call maps
    - `{:error, :no_tool_calls}` - No tool calls in response
    - `{:error, reason}` - Parse error

  ## Examples

      response = %{
        "tool_calls" => [
          %{"id" => "call_1", "function" => %{"name" => "read_file", "arguments" => "{\\"path\\": \\"/f.ex\\"}"}}
        ]
      }
      {:ok, calls} = parse_llm_tool_calls(response)

  """
  @spec parse_llm_tool_calls(map()) :: {:ok, [map()]} | {:error, term()}
  def parse_llm_tool_calls(llm_response) when is_map(llm_response) do
    Executor.parse_tool_calls(llm_response)
  end

  # ============================================================================
  # Private Helpers
  # ============================================================================

  @spec build_execution_context(String.t(), keyword()) ::
          {:ok, Executor.context()} | {:error, term()}
  defp build_execution_context(session_id, opts) do
    timeout = Keyword.get(opts, :timeout)
    project_root = Keyword.get(opts, :project_root)

    context = %{
      session_id: session_id,
      timeout: timeout
    }

    context =
      if project_root do
        Map.put(context, :project_root, project_root)
      else
        context
      end

    {:ok, context}
  end

  @spec generate_call_id() :: String.t()
  defp generate_call_id do
    # Use a unique integer for call ID
    "call_#{:erlang.unique_integer([:positive, :monotonic])}"
  end
end
