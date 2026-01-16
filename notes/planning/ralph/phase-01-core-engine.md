# Phase 1: Core Loop Engine

This phase implements the foundational Ralph Loop infrastructure: the Manager GenServer, basic file structure, simple implementation phase, and the API layer.

## Overview

Phase 1 establishes the core components needed for a functional Ralph Loop:
- Data structures (schemas) for tasks, configuration, and runtime state
- File persistence layer for "files as truth" approach
- Manager GenServer for loop lifecycle management
- Basic Orchestrator Jido Agent with simplified FSM
- Simple Implementation phase for processing file edit tasks
- Public API for external access
- Configuration management and validation
- Prompt template system using EEx

---

## 1.1 RalphLoop Schema Module

Define the core data structures for Ralph Loop operations.

### 1.1.1 Task Schema

Define the task struct for representing work items.

- [ ] 1.1.1.1 Create `lib/jido_code_core/ralph_loop/schema.ex`
- [ ] 1.1.1.2 Define `RalphLoop.Task` struct with fields:
  ```elixir
  defstruct [
    :id,                  # UUID string
    :title,               # Task title
    :description,         # Detailed description
    :status,              # :pending | :researching | :planned | :implementing | :verifying | :completed | :failed
    :priority,            # 1-10, default 5
    :created_at,          # DateTime
    :updated_at,          # DateTime
    :metadata             # Map for extra data
  ]
  ```
- [ ] 1.1.1.3 Add `@type` spec for Task
- [ ] 1.1.1.4 Implement `new/1` factory function with defaults
- [ ] 1.1.1.5 Implement `status_transitions/0` returning valid state transitions
- [ ] 1.1.1.6 Implement `transition_status/2` for state changes with validation
- [ ] 1.1.1.7 Add Jason encoder implementation

### 1.1.2 LoopConfig Schema

Define the configuration struct for loop behavior.

- [ ] 1.1.2.1 Define `RalphLoop.LoopConfig` struct with fields:
  ```elixir
  defstruct [
    :base_branch,         # "main" | "develop", default: "main"
    :branch_prefix,       # "ralph/", default: "jido-ai/"
    :max_iterations,      # Integer, default: 100
    :timeout_seconds,     # Integer, default: 300
    :agent_config,        # Map with provider, model, temperature
    :auto_pr,             # Boolean, default: false
    :required_checks,     # List of strings, default: []
    :custom_prompts_dir   # String | nil
  ]
  ```
- [ ] 1.1.2.2 Add `@type` spec for LoopConfig
- [ ] 1.1.2.3 Implement `new/1` with default values
- [ ] 1.1.2.4 Implement `validate/1` returning `:ok` or `{:error, changeset}`
- [ ] 1.1.2.5 Add Jason encoder implementation

### 1.1.3 LoopState Schema

Define the runtime state struct for the Manager.

- [ ] 1.1.3.1 Define `RalphLoop.LoopState` struct with fields:
  ```elixir
  defstruct [
    :loop_id,             # UUID
    :session_id,          # Associated session
    :status,              # :idle | :running | :paused | :completed | :error
    :current_task_id,     # Currently processing
    :current_phase,       # :research | :plan | :implement | :verify
    :iteration_count,     # Integer
    :started_at,          # DateTime
    :last_activity_at,    # DateTime
    :error_message,       # String | nil
    :completed_tasks,     # List of task IDs
    :failed_tasks         # List of task IDs
  ]
  ```
- [ ] 1.1.3.2 Add `@type` spec for LoopState
- [ ] 1.1.3.3 Implement `new/1` factory function
- [ ] 1.1.3.4 Add Jason encoder implementation

### 1.1.4 Schema Unit Tests

- [ ] 1.1.4.1 Create `test/jido_code_core/ralph_loop/schema_test.exs`
- [ ] 1.1.4.2 Test Task factory with defaults
- [ ] 1.1.4.3 Test status transitions (valid and invalid)
- [ ] 1.1.4.4 Test LoopConfig factory with defaults
- [ ] 1.1.4.5 Test LoopConfig validation (invalid branch, negative max_iterations)
- [ ] 1.1.4.6 Test LoopState factory
- [ ] 1.1.4.7 Test JSON encoding/decoding for all schemas

---

## 1.2 RalphLoop Storage Module

Implement the file persistence layer for "files as truth" approach.

### 1.2.1 Storage Module Structure

Create the storage module for file operations.

- [ ] 1.2.1.1 Create `lib/jido_code_core/ralph_loop/storage.ex`
- [ ] 1.2.1.2 Define `@ralph_dir ".jido_code/ralph"` constant
- [ ] 1.2.1.3 Define file path constants:
  ```elixir
  @config_file "config.json"
  @tasks_file "tasks.json"
  @index_file "index.json"
  @prompts_dir "prompts"
  ```

### 1.2.2 Directory Initialization

- [ ] 1.2.2.1 Implement `ensure_ralph_directory/1` (takes project root)
- [ ] 1.2.2.2 Create `.jido_code/ralph/` if missing
- [ ] 1.2.2.3 Create `.jido_code/ralph/prompts/` if missing
- [ ] 1.2.2.4 Return `:ok` or `{:error, reason}`

### 1.2.3 Config File Operations

- [ ] 1.2.3.1 Implement `load_config/1` - read and decode `config.json`
- [ ] 1.2.3.2 Implement `save_config/2` - encode and write `config.json`
- [ ] 1.2.3.3 Return `{:ok, LoopConfig}` or `{:error, reason}`
- [ ] 1.2.3.4 Create default config if file doesn't exist

### 1.2.4 Tasks File Operations

- [ ] 1.2.4.1 Implement `load_tasks/1` - read `tasks.json`
- [ ] 1.2.4.2 Implement `save_tasks/2` - write `tasks.json`
- [ ] 1.2.4.3 Return `{:ok, [Task]}` or `{:error, reason}`
- [ ] 1.2.4.4 Support empty tasks list (return `[]`)

### 1.2.5 Index File Operations

- [ ] 1.2.5.1 Implement `load_index/1` - read `index.json`
- [ ] 1.2.5.2 Implement `save_index/2` - write `index.json`
- [ ] 1.2.5.3 Index structure: `%{loops: [%{loop_id, started_at, status}]}`
- [ ] 1.2.5.4 Implement `register_loop/3` - add new entry to index
- [ ] 1.2.5.5 Implement `update_loop_status/3` - update status in index

### 1.2.6 Task-Specific Artifacts

- [ ] 1.2.6.1 Implement `task_dir/2` - get path for task directory
- [ ] 1.2.6.2 Implement `ensure_task_dir/2` - create if missing
- [ ] 1.2.6.3 Implement `read_task_artifact/3` - read task-specific file
- [ ] 1.2.6.4 Implement `write_task_artifact/4` - write task-specific file
- [ ] 1.2.6.5 Implement `append_progress/3` - append to `progress.log`

### 1.2.7 Storage Unit Tests

- [ ] 1.2.7.1 Create `test/jido_code_core/ralph_loop/storage_test.exs`
- [ ] 1.2.7.2 Test directory initialization creates all subdirectories
- [ ] 1.2.7.3 Test config save/load roundtrip
- [ ] 1.2.7.4 Test config returns defaults when missing
- [ ] 1.2.7.5 Test tasks save/load roundtrip
- [ ] 1.2.7.6 Test tasks returns empty list when missing
- [ ] 1.2.7.7 Test index register_loop adds entry
- [ ] 1.2.7.8 Test index update_loop_status modifies entry
- [ ] 1.2.7.9 Test task directory operations
- [ ] 1.2.7.10 Test progress log appending

---

## 1.3 RalphLoop Manager GenServer

Implement the core Manager GenServer for loop lifecycle management.

### 1.3.1 Manager Module Structure

- [ ] 1.3.1.1 Create `lib/jido_code_core/ralph_loop/manager.ex`
- [ ] 1.3.1.2 `use GenServer` with `@name __MODULE__`
- [ ] 1.3.1.3 Define `@registry JidoCodeCore.Session.ProcessRegistry`

### 1.3.2 Manager State

- [ ] 1.3.2.1 Define internal state struct:
  ```elixir
  defstruct [
    :loop_state,          # LoopState
    :config,              # LoopConfig
    :tasks,               # [Task]
    :session_id,          # Associated session
    :project_root,        # Project path
    :orchestrator_pid     # pid | nil
  ]
  ```

### 1.3.3 Manager API (Client Functions)

- [ ] 1.3.3.1 Implement `start_link/1` - start manager with opts
- [ ] 1.3.3.2 Implement `start_loop/2` - public API to start a loop
- [ ] 1.3.3.3 Implement `stop_loop/1` - public API to stop a loop
- [ ] 1.3.3.4 Implement `pause_loop/1` - pause running loop
- [ ] 1.3.3.5 Implement `resume_loop/1` - resume paused loop
- [ ] 1.3.3.6 Implement `get_status/1` - get current loop state
- [ ] 1.3.3.7 Implement `add_task/2` - add new task to loop
- [ ] 1.3.3.8 Implement `list_tasks/1` - get all tasks

### 1.3.4 GenServer Callbacks - init

- [ ] 1.3.4.1 Implement `init/1` with opts validation
- [ ] 1.3.4.2 Load config from storage
- [ ] 1.3.4.3 Load tasks from storage
- [ ] 1.3.4.4 Register in ProcessRegistry with key `{:ralph_loop, session_id}`
- [ ] 1.3.4.5 Return `{:ok, state}` or `{:stop, reason}`

### 1.3.5 GenServer Callbacks - handle_call

- [ ] 1.3.5.1 `handle_call(:get_status, _, state)` - return LoopState
- [ ] 1.3.5.2 `handle_call(:pause, _, state)` - set status to :paused
- [ ] 1.3.5.3 `handle_call(:resume, _, state)` - set status to :running, trigger next iteration
- [ ] 1.3.5.4 `handle_call({:add_task, task}, _, state)` - add to tasks list, persist
- [ ] 1.3.5.5 `handle_call(:list_tasks, _, state)` - return tasks list
- [ ] 1.3.5.6 `handle_call(:stop, _, state)` - gracefully stop, cleanup

### 1.3.6 GenServer Callbacks - handle_cast

- [ ] 1.3.6.1 `handle_cast(:next_iteration, state)` - trigger next task/phase
- [ ] 1.3.6.2 `handle_cast({:phase_complete, result}, state)` - handle phase completion
- [ ] 1.3.6.3 `handle_cast({:phase_failed, error}, state)` - handle phase failure
- [ ] 1.3.6.4 `handle_cast(:broadcast_status, state)` - publish PubSub update

### 1.3.7 GenServer Callbacks - handle_info

- [ ] 1.3.7.1 `handle_info(:timeout, state)` - handle phase timeout
- [ ] 1.3.7.2 `handle_info({:DOWN, ref}, state)` - handle orchestrator death
- [ ] 1.3.7.3 `handle_info(:next_iteration, state)` - delayed iteration trigger

### 1.3.8 Loop Control Logic

- [ ] 1.3.8.1 Implement `select_next_task/1` - find highest priority pending task
- [ ] 1.3.8.2 Implement `check_stop_conditions/1` - evaluate termination criteria
- [ ] 1.3.8.3 Implement `increment_iteration/1` - update count, check max
- [ ] 1.3.8.4 Implement `transition_task_status/3` - update task status, persist

### 1.3.9 Manager Unit Tests

- [ ] 1.3.9.1 Create `test/jido_code_core/ralph_loop/manager_test.exs`
- [ ] 1.3.9.2 Test manager starts with valid config
- [ ] 1.3.9.3 Test manager fails with invalid config
- [ ] 1.3.9.4 Test start_loop begins processing
- [ ] 1.3.9.5 Test stop_loop gracefully terminates
- [ ] 1.3.9.6 Test pause_loop stops processing
- [ ] 1.3.9.7 Test resume_loop continues processing
- [ ] 1.3.9.8 Test get_status returns current state
- [ ] 1.3.9.9 Test add_task adds to tasks list
- [ ] 1.3.9.10 Test list_tasks returns all tasks
- [ ] 1.3.9.11 Test select_next_task picks highest priority
- [ ] 1.3.9.12 Test check_stop_conditions with various states

---

## 1.4 RalphLoop Orchestrator Jido Agent

Implement the basic orchestrator agent for coordinating loop execution.

### 1.4.1 Orchestrator Module Structure

- [ ] 1.4.1.1 Create `lib/jido_code_core/ralph_loop/orchestrator.ex`
- [ ] 1.4.1.2 `use Jido.Agent` with proper configuration
- [ ] 1.4.1.3 Define agent name, description

### 1.4.2 Orchestrator State Schema

- [ ] 1.4.2.1 Define agent state struct:
  ```elixir
  defstruct [
    :loop_id,
    :session_id,
    :current_task,
    :current_phase,
    :iteration,
    :config
  ]
  ```

### 1.4.3 Orchestrator Actions

- [ ] 1.4.3.1 Define `SelectTask` action - pick next pending task
- [ ] 1.4.3.2 Define `StartPhase` action - begin a phase
- [ ] 1.4.3.3 Define `CompletePhase` action - mark phase done
- [ ] 1.4.3.4 Define `FailTask` action - mark task as failed
- [ ] 1.4.3.5 Define `CompleteTask` action - mark task completed

### 1.4.4 Orchestrator Directives

- [ ] 1.4.4.1 Emit `:task_selected` signal with task info
- [ ] 1.4.4.2 Emit `:phase_started` signal
- [ ] 1.4.4.3 Emit `:phase_completed` signal
- [ ] 1.4.4.4 Emit `:loop_completed` signal
- [ ] 1.4.4.5 Emit `:loop_failed` signal

### 1.4.5 Orchestrator FSM Strategy (Phase 1 - Simplified)

- [ ] 1.4.5.1 Define states: `:idle`, `:implementing`, `:verifying`, `:completed`, `:error`
- [ ] 1.4.5.2 Define transitions: `:idle` → `:implementing` → `:verifying` → `:idle`
- [ ] 1.4.5.3 Implement `:idle` state logic - select task, start implementing
- [ ] 1.4.5.4 Implement `:implementing` state - call Implement phase agent
- [ ] 1.4.5.5 Implement `:verifying` state - run verification checks
- [ ] 1.4.5.6 Implement `:completed` state - all tasks done
- [ ] 1.4.5.7 Implement `:error` state - unrecoverable error

### 1.4.6 Orchestrator Unit Tests

- [ ] 1.4.6.1 Create `test/jido_code_core/ralph_loop/orchestrator_test.exs`
- [ ] 1.4.6.2 Test agent initializes with state
- [ ] 1.4.6.3 Test SelectTask action picks pending task
- [ ] 1.4.6.4 Test StartPhase action emits directive
- [ ] 1.4.6.5 Test CompletePhase action updates state
- [ ] 1.4.6.6 Test FSM transitions between states
- [ ] 1.4.6.7 Test loop completes when no tasks remain

---

## 1.5 Implement Phase Agent (Basic)

Implement the basic implementation phase that processes simple file edit tasks.

### 1.5.1 Implement Module Structure

- [ ] 1.5.1.1 Create `lib/jido_code_core/ralph_loop/phases/implement.ex`
- [ ] 1.5.1.2 `use Jido.Agent` with proper configuration

### 1.5.2 Implement Agent State

- [ ] 1.5.2.1 Define state struct:
  ```elixir
  defstruct [
    :task_id,
    :session_id,
    :changes_made,
    :test_results
  ]
  ```

### 1.5.3 Implement Actions

- [ ] 1.5.3.1 Define `ExecuteChanges` action - apply planned changes
- [ ] 1.5.3.2 Define `RunTests` action - execute test command
- [ ] 1.5.3.3 Define `CommitChanges` action - git commit with message

### 1.5.4 LLM Integration

- [ ] 1.5.4.1 Implement `call_llm/3` - use JidoCodeCore.API.Agent
- [ ] 1.5.4.2 Pass task description as prompt
- [ ] 1.5.4.3 Include available tools in agent call
- [ ] 1.5.4.4 Parse tool call results from LLM response

### 1.5.5 Tool Execution

- [ ] 1.5.5.1 Use `JidoCodeCore.API.Tools` for tool access
- [ ] 1.5.5.2 Support `read_file`, `write_file`, `edit_file`
- [ ] 1.5.5.3 Support `run_command` for tests
- [ ] 1.5.5.4 Support `git_command` for commits

### 1.5.6 Implement Unit Tests

- [ ] 1.5.6.1 Create `test/jido_code_core/ralph_loop/phases/implement_test.exs`
- [ ] 1.5.6.2 Test agent initializes with task
- [ ] 1.5.6.3 Test ExecuteChanges applies file changes
- [ ] 1.5.6.4 Test RunTests executes command
- [ ] 1.5.6.5 Test CommitChanges creates git commit

---

## 1.6 RalphLoop API Module

Create the public API for Ralph Loop operations.

### 1.6.1 API Module Structure

- [ ] 1.6.1.1 Create `lib/jido_code_core/api/ralph_loop.ex`
- [ ] 1.6.1.2 Add `@doc` headers for all functions

### 1.6.2 Loop Management API

- [ ] 1.6.2.1 Implement `start_loop/2` - start loop for session
  ```elixir
  @spec start_loop(session_id :: String.t(), opts :: keyword()) :: {:ok, loop_id :: String.t()} | {:error, term()}
  ```
- [ ] 1.6.2.2 Implement `stop_loop/1` - stop running loop
  ```elixir
  @spec stop_loop(loop_id :: String.t()) :: :ok | {:error, term()}
  ```
- [ ] 1.6.2.3 Implement `pause_loop/1` - pause loop
  ```elixir
  @spec pause_loop(loop_id :: String.t()) :: :ok | {:error, term()}
  ```
- [ ] 1.6.2.4 Implement `resume_loop/1` - resume paused loop
  ```elixir
  @spec resume_loop(loop_id :: String.t()) :: :ok | {:error, term()}
  ```

### 1.6.3 Status and Query API

- [ ] 1.6.3.1 Implement `get_loop_status/1` - get loop state
  ```elixir
  @spec get_loop_status(loop_id :: String.t()) :: {:ok, map()} | {:error, term()}
  ```
- [ ] 1.6.3.2 Implement `list_loops/0` - list all loops
  ```elixir
  @spec list_loops() :: {:ok, [map()]} | {:error, term()}
  ```
- [ ] 1.6.3.3 Implement `get_loop_config/1` - get loop config
  ```elixir
  @spec get_loop_config(loop_id :: String.t()) :: {:ok, LoopConfig.t()} | {:error, term()}
  ```

### 1.6.4 Task Management API

- [ ] 1.6.4.1 Implement `add_tasks/2` - add tasks to loop
  ```elixir
  @spec add_tasks(loop_id :: String.t(), tasks :: [map()]) :: :ok | {:error, term()}
  ```
- [ ] 1.6.4.2 Implement `list_tasks/1` - get all tasks
  ```elixir
  @spec list_tasks(loop_id :: String.t()) :: {:ok, [Task.t()]} | {:error, term()}
  ```
- [ ] 1.6.4.3 Implement `get_task/2` - get specific task
  ```elixir
  @spec get_task(loop_id :: String.t(), task_id :: String.t()) :: {:ok, Task.t()} | {:error, term()}
  ```

### 1.6.5 Configuration API

- [ ] 1.6.5.1 Implement `update_config/2` - update loop config
  ```elixir
  @spec update_config(loop_id :: String.t(), config :: map()) :: :ok | {:error, term()}
  ```
- [ ] 1.6.5.2 Implement `get_config/1` - get current config
  ```elixir
  @spec get_config(loop_id :: String.t()) :: {:ok, map()} | {:error, term()}
  ```

### 1.6.6 API Unit Tests

- [ ] 1.6.6.1 Create `test/jido_code_core/api/ralph_loop_test.exs`
- [ ] 1.6.6.2 Test start_loop creates manager and returns loop_id
- [ ] 1.6.6.3 Test stop_loop terminates manager
- [ ] 1.6.6.4 Test pause_loop changes status to paused
- [ ] 1.6.6.5 Test resume_loop changes status back to running
- [ ] 1.6.6.6 Test get_loop_status returns current state
- [ ] 1.6.6.7 Test list_loops returns all active loops
- [ ] 1.6.6.8 Test add_tasks persists to storage
- [ ] 1.6.6.9 Test list_tasks returns all tasks for loop

---

## 1.7 RalphLoop Configuration Module

Manage configuration loading and validation.

### 1.7.1 Config Module Structure

- [ ] 1.7.1.1 Create `lib/jido_code_core/ralph_loop/config.ex`
- [ ] 1.7.1.2 Define default configuration values

### 1.7.2 Default Configuration

- [ ] 1.7.2.1 Define `defaults/0` returning:
  ```elixir
  %{
    base_branch: "main",
    branch_prefix: "jido-ai/",
    max_iterations: 100,
    timeout_seconds: 300,
    auto_pr: false,
    required_checks: []
  }
  ```

### 1.7.3 Config Merging

- [ ] 1.7.3.1 Implement `merge/2` - merge user config with defaults
- [ ] 1.7.3.2 Deep merge for agent_config sub-map
- [ ] 1.7.3.3 Override with session config if present

### 1.7.4 Config Validation

- [ ] 1.7.4.1 Implement `validate_branch_name/1` - check valid branch
- [ ] 1.7.4.2 Implement `validate_max_iterations/1` - positive integer
- [ ] 1.7.4.3 Implement `validate_timeout/1` - reasonable range
- [ ] 1.7.4.4 Implement `validate_required_checks/1` - list of strings

### 1.7.5 Config Unit Tests

- [ ] 1.7.5.1 Create `test/jido_code_core/ralph_loop/config_test.exs`
- [ ] 1.7.5.2 Test defaults returns expected values
- [ ] 1.7.5.3 Test merge preserves defaults
- [ ] 1.7.5.4 Test merge applies user overrides
- [ ] 1.7.5.5 Test validate_branch_name accepts valid names
- [ ] 1.7.5.6 Test validate_branch_name rejects invalid names
- [ ] 1.7.5.7 Test validate_max_iterations accepts positive integers

---

## 1.8 Prompt Template System

Create the EEx template system for phase prompts.

### 1.8.1 Prompts Module Structure

- [ ] 1.8.1.1 Create `lib/jido_code_core/ralph_loop/prompts.ex`
- [ ] 1.8.1.2 Define `@prompts_dir ".jido_code/ralph/prompts"`

### 1.8.2 Template Rendering

- [ ] 1.8.2.1 Implement `render_prompt/3` - render EEx template
  ```elixir
  @spec render_prompt(phase :: atom(), assigns :: map(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}
  ```
- [ ] 1.8.2.2 Support custom prompts_dir from config
- [ ] 1.8.2.3 Fall back to built-in templates

### 1.8.3 Built-in Templates (Phase 1)

- [ ] 1.8.3.1 Create default implement prompt template
  ```elixir
  @impl_template """
  You are implementing the following task:
  Title: <%= @task.title %>
  Description: <%= @task.description %>

  Available tools: <%= Enum.join(@tools, ", ") %>

  Implement the changes, run tests, and commit.
  """
  ```
- [ ] 1.8.3.2 Create default verify prompt template

### 1.8.4 Prompts Unit Tests

- [ ] 1.8.4.1 Create `test/jido_code_core/ralph_loop/prompts_test.exs`
- [ ] 1.8.4.2 Test render_prompt with valid template
- [ ] 1.8.4.3 Test render_prompt with custom assigns
- [ ] 1.8.4.4 Test render_prompt falls back to built-in
- [ ] 1.8.4.5 Test render_prompt errors on missing template

---

## 1.9 Phase 1 Integration Tests

Comprehensive integration tests for the core loop engine.

### 1.9.1 End-to-End Loop Test

- [ ] 1.9.1.1 Create `test/jido_code_core/ralph_loop/integration_test.exs`
- [ ] 1.9.1.2 Test: Initialize ralph directory
- [ ] 1.9.1.3 Test: Start loop with simple task list
- [ ] 1.9.1.4 Test: Loop processes tasks sequentially
- [ ] 1.9.1.5 Test: Loop stops when all tasks complete
- [ ] 1.9.1.6 Test: Loop state persists across restart

### 1.9.2 Storage Integration

- [ ] 1.9.2.1 Test: Config roundtrip through storage
- [ ] 1.9.2.2 Test: Tasks persist correctly
- [ ] 1.9.2.3 Test: Index tracks loop runs

### 1.9.3 API Integration

- [ ] 1.9.3.1 Test: Complete workflow through API
- [ ] 1.9.3.2 Test: Error handling through API

---

## Phase 1 Success Criteria

| Criterion | Status |
|-----------|--------|
| **Schema**: Task, LoopConfig, LoopState defined | Pending |
| **Storage**: File persistence working | Pending |
| **Manager**: GenServer lifecycle complete | Pending |
| **Orchestrator**: Basic FSM implemented | Pending |
| **Implement**: Phase agent processes tasks | Pending |
| **API**: Public interface complete | Pending |
| **Config**: Validation and defaults working | Pending |
| **Prompts**: EEx template system | Pending |
| **Tests**: 80% coverage minimum | Pending |

---

## Phase 1 Critical Files

**New Files:**
- `lib/jido_code_core/ralph_loop/schema.ex`
- `lib/jido_code_core/ralph_loop/storage.ex`
- `lib/jido_code_core/ralph_loop/manager.ex`
- `lib/jido_code_core/ralph_loop/orchestrator.ex`
- `lib/jido_code_core/ralph_loop/phases/implement.ex`
- `lib/jido_code_core/ralph_loop/config.ex`
- `lib/jido_code_core/ralph_loop/prompts.ex`
- `lib/jido_code_core/api/ralph_loop.ex`
- `test/jido_code_core/ralph_loop/schema_test.exs`
- `test/jido_code_core/ralph_loop/storage_test.exs`
- `test/jido_code_core/ralph_loop/manager_test.exs`
- `test/jido_code_core/ralph_loop/orchestrator_test.exs`
- `test/jido_code_core/ralph_loop/phases/implement_test.exs`
- `test/jido_code_core/ralph_loop/config_test.exs`
- `test/jido_code_core/ralph_loop/prompts_test.exs`
- `test/jido_code_core/api/ralph_loop_test.exs`
- `test/jido_code_core/ralph_loop/integration_test.exs`
