# Phase 1.3: Base Types

Define shared base types and schemas for the new architecture.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Type System Flow                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────┐     ┌─────────────────────────────┐      │
│   │ Agent       │────>│ Zoi Schema Validation       │      │
│   │ State       │     │ • Type definitions          │      │
│   │             │     │ • Default values            │      │
│   └─────────────┘     │ • Validation rules          │      │
│         │             └─────────────────────────────┘      │
│         v                           │                       │
│   ┌─────────────────────────────────┼───────────────────┐  │
│   │         Agent State Fields      │                   │  │
│   │  • session_id, project_path     │                   │  │
│   │  • messages, reasoning_steps    │                   │  │
│   │  • todos, file tracking         │                   │  │
│   │  • llm_config                   │                   │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/agent/schemas.ex` | Zoi schema definitions |

---

## 1.3.1: Define Session Agent Schema

Create Zoi schema for the session agent state.

### 1.3.1.1: Create Agent Schemas Module
- [ ] Create `lib/jido_code_core/agent/` directory
- [ ] Create `lib/jido_code_core/agent/schemas.ex`
- [ ] Add `@session_agent_schema` with:

```elixir
@session_agent_schema Zoi.object(%{
  # Core session fields
  session_id: Zoi.string(description: "Unique session identifier")
    |> Zoi.default(nil),
  project_path: Zoi.string(description: "Project root path")
    |> Zoi.default(nil),
  language: Zoi.atom(description: "Primary programming language")
    |> Zoi.default(:elixir),

  # Messages and conversation
  messages: Zoi.list(Zoi.any(), description: "Conversation messages")
    |> Zoi.default([]),
  reasoning_steps: Zoi.list(Zoi.any(), description: "Chain-of-thought steps")
    |> Zoi.default([]),
  tool_calls: Zoi.list(Zoi.any(), description: "Tool call records")
    |> Zoi.default([]),
  todos: Zoi.list(Zoi.any(), description: "Task tracking")
    |> Zoi.default([]),

  # File tracking
  file_reads: Zoi.map(Zoi.string(), Zoi.any(), description: "Tracked file reads")
    |> Zoi.default(%{}),
  file_writes: Zoi.map(Zoi.string(), Zoi.any(), description: "Tracked file writes")
    |> Zoi.default(%{}),

  # LLM config
  llm_config: Zoi.object(%{
    provider: Zoi.string() |> Zoi.default("anthropic"),
    model: Zoi.string() |> Zoi.default("claude-3-5-sonnet-20241022"),
    temperature: Zoi.float() |> Zoi.default(0.7),
    max_tokens: Zoi.integer() |> Zoi.default(4096)
  }) |> Zoi.default(%{}),

  # Timestamps
  created_at: Zoi.any() |> Zoi.default(nil),
  updated_at: Zoi.any() |> Zoi.default(nil)
}, coerce: true)
```

### 1.3.1.2: Add Schema Validation Functions
- [ ] Add `validate_session_agent/1` function
- [ ] Add `apply_defaults/1` function
- [ ] Add type specifications

### 1.3.1.3: Create Tests for Schema
- [ ] Test valid session agent creation
- [ ] Test default value application
- [ ] Test validation errors
- [ ] Test coercion

---

## Phase 1.3 Success Criteria

1. **Schemas**: Zoi schemas defined and validate correctly
2. **Defaults**: Default values apply correctly
3. **Validation**: All schema rules work as expected
4. **Tests**: All schema tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/agent/schemas.ex` | ~150 (new) | Define Zoi schemas |
| `test/jido_code_core/agent/schemas_test.exs` | ~100 (new) | Schema tests |

## Rollback Plan

```bash
rm -rf lib/jido_code_core/agent/
rm -rf test/jido_code_core/agent/
```

## Phase 1 Success Criteria

1. **Dependencies**: All Jido 2.0 dependencies compile without conflicts
2. **Error Handling**: Splode error helpers available
3. **Base Types**: Schemas defined with validation
4. **Tests**: All tests pass

Proceed to [Phase 2: State Management](../phase02_state_management/overview.md)
