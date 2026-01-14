# JidoCodeCore

**Core AI Agent Library for JidoCode** - The headless, TUI-independent core of JidoCode.

JidoCodeCore provides the essential building blocks for AI-powered coding assistants, including session management, tool execution, and agent orchestration - without any terminal UI dependencies.

## Overview

JidoCodeCore is the extracted core library from [JidoCode](https://github.com/your-repo/jido_code), designed to be:

- **Headless**: No TUI dependencies - use in any application (CLI, web, desktop)
- **Namespace-Isolated**: Uses `JidoCodeCore.*` namespace to avoid conflicts
- **Tested**: 236+ tests covering core functionality
- **Agent-Ready**: Built for LLM agents with tool-calling support

## Installation

Add `jido_code_core` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jido_code_core, "~> 0.1.0"}
  ]
end
```

## Quick Start

### Starting a Session

```elixir
# Start a new session for a project
{:ok, session} = JidoCodeCore.API.Session.start_session(
  project_path: "/path/to/project",
  name: "My Project"
)

# Send a message to the agent
{:ok, response} = JidoCodeCore.API.Agent.send_message(
  session.id,
  "List all files in src/"
)

# Stop the session when done
:ok = JidoCodeCore.API.Session.stop_session(session.id)
```

### Using Tools Directly

```elixir
# List available tools
tools = JidoCodeCore.API.Tools.list_tools()

# Execute a tool
{:ok, result} = JidoCodeCore.API.Tools.execute_tool(
  "session-id",
  "read_file",
  %{"path" => "/path/to/file.ex"}
)
```

## Architecture

```
JidoCodeCore
├── API/                    # Public API surface
│   ├── Session             # Session lifecycle (start/stop/list)
│   ├── Agent              # Agent communication (send messages)
│   ├── Tools              # Tool execution interface
│   ├── Config             # Configuration management
│   └── Memory             # Memory operations
├── Session/                # Session management
│   ├── Supervisor         # Dynamic supervisor for sessions
│   ├── Registry           # ETS-based session registry
│   ├── State              # GenServer for session state
│   └── Persistence        # Session save/load (placeholder)
├── Tools/                  # Tool system
│   ├── Registry           # Tool registration (persistent_term)
│   ├── Executor           # Tool execution coordinator
│   ├── Tool/Param/Result  # Core abstractions
│   ├── Handlers/          # Tool implementations
│   ├── Definitions/       # Pre-defined tools
│   └── Security/          # Path validation, sandboxing
├── Agents/                 # LLM Agents
│   └── LLMAgent           # Anthropic/OpenAI agent
├── Memory/                 # Memory systems
│   ├── ShortTerm          # Working memory, access log
│   ├── LongTerm           # Triple store, knowledge graph
│   └── Promotion          # Memory promotion engine
└── KnowledgeGraph/         # RDF knowledge store
```

## Public API Modules

### `JidoCodeCore.API.Session`

Session lifecycle and management:

```elixir
# Start a session
{:ok, session} = API.Session.start_session(project_path: "/path")

# List all sessions
sessions = API.Session.list_sessions()

# Get session info
{:ok, session} = API.Session.get_session("session-id")

# Check if running
API.Session.session_running?("session-id")  # => true/false

# Stop a session
:ok = API.Session.stop_session("session-id")
```

### `JidoCodeCore.API.Agent`

Agent communication for LLM interaction:

```elixir
# Send a message
{:ok, response} = API.Agent.send_message("session-id", "Hello!")

# Stream responses
:ok = API.Agent.send_message_stream("session-id", "Explain this code")

# Get agent status
{:ok, status} = API.Agent.get_status("session-id")

# Reconfigure with new model
:ok = API.Agent.reconfigure_agent("session-id", model: "gpt-4")
```

### `JidoCodeCore.API.Tools`

Tool execution and management:

```elixir
# List available tools
tools = API.Tools.list_tools()

# Get tool schema
{:ok, schema} = API.Tools.get_tool_schema("read_file")

# Execute a tool
{:ok, result} = API.Tools.execute_tool("sid", "read_file", %{"path" => "/f"})

# Execute multiple tools
{:ok, results} = API.Tools.execute_tools("sid", [
  %{id: "1", name: "read_file", arguments: %{"path" => "/a"}},
  %{id: "2", name: "read_file", arguments: %{"path" => "/b"}}
])

# Get LLM-format tool definitions
tools_for_llm = API.Tools.tools_for_llm()
```

### `JidoCodeCore.API.Config`

Configuration management:

```elixir
# Get a setting
value = API.Config.get_setting("model", "default-model")

# Validate settings
{:ok, validated} = API.Config.validate_settings(%{model: "claude-3-5-sonnet-20241022"})

# List models for provider
{:ok, models} = API.Config.list_models_for_provider("anthropic")
```

### `JidoCodeCore.API.Memory`

Memory operations:

```elixir
# Store a memory
{:ok, memory} = API.Memory.remember("session-id", "Important fact")

# Recall memories
{:ok, memories} = API.Memory.recall("session-id", limit: 10)

# Search memory graph
{:ok, results} = API.Memory.search_graph("session-id", "memory-id", query: "fact")

# Forget a memory
:ok = API.Memory.forget("session-id", "memory-id")
```

## Tool System

JidoCodeCore includes a comprehensive tool system with 40+ pre-built tools:

### File Operations
- `read_file` - Read file contents
- `write_file` - Write/create files
- `edit_file` - String replacement in files
- `list_directory` - List directory contents
- `file_info` - Get file metadata
- `create_directory` - Create directories
- `delete_file` - Delete files

### Search
- `grep` - Search file contents with regex
- `find_files` - Find files by pattern
- `glob_search` - Glob-based search

### Shell
- `run_command` - Execute allowlisted commands (git, mix, npm, etc.)

### Web
- `web_fetch` - Fetch and parse web content
- `web_search` - Search the web via DuckDuckGo

### Git
- `git_command` - Run git commands

### Livebook
- `livebook_edit` - Edit Livebook (.livemd) cells

### LSP
- `get_diagnostics` - Get LSP diagnostics for a file
- `go_to_definition` - Go to symbol definition
- `find_references` - Find symbol references
- `get_hover_info` - Get hover documentation

## Session Management

Each session is isolated with:

- **Independent conversation history** (1000 message limit)
- **Tool sandbox** with path validation
- **LLM configuration** (provider, model, temperature)
- **Memory context** (short-term and long-term)
- **PubSub topics** for event streaming

## Dependencies

```elixir
# Core
{:jido, "~> 1.2"}
{:jido_ai, "~> 0.5"}

# Communication
{:phoenix_pubsub, "~> 2.1"}

# Knowledge Graph
{:rdf, "~> 2.0"}
{:libgraph, "~> 0.16"}

# Web Tools
{:floki, "~> 0.36"}

# Security
{:luerl, "~> 1.2"}  # Lua sandbox
```

## Documentation

Full documentation available on [HexDocs](https://hexdocs.pm/jido_code_core).

Generate docs locally:

```bash
mix docs
```

## Testing

Run the test suite:

```bash
mix test                      # Run all tests
mix test --cover              # With coverage
mix test test/jido_code_core/api/  # Specific directory
```

Current coverage: **236 tests, 0 failures**

## Namespace

All modules use `JidoCodeCore.*` namespace:

- `JidoCodeCore.Session` - Session structs and logic
- `JidoCodeCore.Tools.*` - Tool system
- `JidoCodeCore.Agents.*` - LLM agents
- `JidoCodeCore.Memory.*` - Memory systems
- `JidoCodeCore.API.*` - Public API

## License

Same as [JidoCode](https://github.com/your-repo/jido_code).
