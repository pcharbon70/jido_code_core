# Phase 2.1: Agent Structure

Create the Jido.Agent structure to replace the GenServer-based Session.State.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CodeSessionAgent Structure                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              Jido.Agent.CodeSession                     │  │
│   │  use Jido.Agent                                         │  │
│   │    name: "code_session"                                 │  │
│   │    strategy: Jido.Agent.Strategy.Direct                 │  │
│   │    skills: []                                           │  │
│   │    schema: [from Phase 1.3]                             │  │
│   └─────────────────────────────────────────────────────────┘  │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              cmd/2 (Pure Function)                       │  │
│   │  • Receive signals                                      │  │
│   │  • Apply StateOps                                       │  │
│   │  • Return Directives                                    │  │
│   │  • Return {updated_agent, directives}                   │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/agent/code_session.ex` | Main agent definition |

---

## 2.1.1: Create CodeSessionAgent Module

Define the core agent structure.

### 2.1.1.1: Create Agent File
- [ ] Create `lib/jido_code_core/agent/code_session.ex`
- [ ] Add `use Jido.Agent` with configuration:

```elixir
defmodule JidoCodeCore.Agent.CodeSession do
  use Jido.Agent,
    name: "code_session",
    description: "A code editing session agent",
    category: "code",
    vsn: "2.0.0",

    # Use Phase 1.3 schema
    schema: [
      # Core session fields
      session_id: [type: :string, default: nil],
      project_path: [type: :string, default: nil],
      language: [type: :atom, default: :elixir],

      # Messages and conversation
      messages: [type: :list, default: []],
      reasoning_steps: [type: :list, default: []],
      tool_calls: [type: :list, default: []],
      todos: [type: :list, default: []],

      # File tracking
      file_reads: [type: :map, default: %{}],
      file_writes: [type: :map, default: %{}],

      # Memory tracking
      working_context: [type: :map, default: %{}],
      pending_memories: [type: :list, default: []],

      # LLM config
      llm_config: [type: :map, default: %{}],

      # Timestamps
      created_at: [type: :struct, default: nil],
      updated_at: [type: :struct, default: nil]
    ],

    strategy: Jido.Agent.Strategy.Direct,
    skills: []
end
```

### 2.1.1.2: Add Agent Type Specs
- [ ] Add `@type t()` specification
- [ ] Add specs for exported functions
- [ ] Document agent state structure

### 2.1.1.3: Create Agent Tests
- [ ] Test agent creation with `CodeSession.new()`
- [ ] Test agent initialization with defaults
- [ ] Test agent initialization with custom values
- [ ] Verify schema validation

---

## 2.1.2: Add Agent Lifecycle Hooks

Implement lifecycle hooks for session management.

### 2.1.2.1: Implement on_before_cmd/2
- [ ] Add timestamp update before commands
- [ ] Add logging hook
- [ ] Add validation hook for critical changes

### 2.1.2.2: Implement on_after_cmd/3
- [ ] Add post-processing hook
- [ ] Add telemetry emission
- [ ] Add state change notifications

### 2.1.2.3: Create Hook Tests
- [ ] Verify hooks fire in correct order
- [ ] Test timestamp updates
- [ ] Test error handling in hooks

---

## 2.1.3: Create Basic Signal Handlers

Add initial signal handlers for core operations.

### 2.1.3.1: Implement Append Message Handler
- [ ] Create `AppendMessage` action
- [ ] Add StateOp.SetState for message append
- [ ] Add validation for message structure

### 2.1.3.2: Implement Update Todos Handler
- [ ] Create `UpdateTodos` action
- [ ] Add StateOp.SetState for todos update
- [ ] Add validation for todo structure

### 2.1.3.3: Create Handler Tests
- [ ] Test message appending
- [ ] Test todo updates
- [ ] Verify state persistence

---

## Phase 2.1 Success Criteria

1. **Agent**: CodeSessionAgent compiles and starts
2. **Initialization**: Agent creates with valid defaults
3. **Hooks**: Lifecycle hooks fire correctly
4. **Handlers**: Basic signal handlers working
5. **Tests**: All agent tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/agent/code_session.ex` | ~200 (new) | Create agent |
| `test/jido_code_core/agent/code_session_test.exs` | ~150 (new) | Agent tests |

## Rollback Plan

```bash
rm -f lib/jido_code_core/agent/code_session.ex
rm -f test/jido_code_core/agent/code_session_test.exs
```

Proceed to [Section 2.2: StateOps Migration](./02-stateops-migration.md)
