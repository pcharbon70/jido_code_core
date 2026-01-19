# Phase 6.2: State Initialization

Set up session state initialization.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   State Initialization Flow                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────┐     initialize   ┌─────────────────┐       │
│   │ Session Params   │────────────────>│ Agent State     │       │
│   │ (input)          │                 │ (pure data)     │       │
│   └─────────────────┘                 └─────────────────┘       │
│          │                                      │                │
│          │ session_id, project_path,           │                │
│          │ language, config                    │                │
│          │                                      │                │
│          ▼                                      ▼                │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              State Initializer                            │  │
│   │  • Set default values                                     │  │
│   │  • Validate input                                         │  │
│   │  • Apply schema defaults                                  │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/agent/state_initializer.ex` | State initialization logic |
| `lib/jido_code_core/agent/code_session.ex` | Init callbacks |

---

## 6.2.1: Create State Initializer

Build session state initialization.

### 6.2.1.1: Create StateInitializer Module
- [ ] Create `lib/jido_code_core/agent/state_initializer.ex`

```elixir
defmodule JidoCodeCore.Agent.StateInitializer do
  @moduledoc """
  Initialize session state from parameters.
  """

  alias JidoCodeCore.Agent.CodeSession

  @doc """
  Initialize agent state from session parameters.
  """
  def init(params) when is_map(params) do
    %{
      session_id: Map.get(params, :session_id, generate_session_id()),
      project_path: Map.get(params, :project_path),
      language: Map.get(params, :language, :elixir),
      messages: [],
      reasoning_steps: [],
      tool_calls: [],
      todos: [],
      file_reads: %{},
      file_writes: %{},
      llm_config: Map.get(params, :llm_config, %{}),
      working_context: %{},
      pending_memories: [],
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  defp generate_session_id do
    "session_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
  end
end
```

### 6.2.1.2: Add Validation
- [ ] Validate required fields
- [ ] Check for valid paths
- [ ] Handle edge cases

### 6.2.1.3: Add Error Handling
- [ ] Handle invalid input
- [ ] Provide clear error messages
- [ ] Log initialization failures

---

## 6.2.2: Add Init Callbacks

Auto-initialize sessions on creation.

### 6.2.2.1: Update CodeSessionAgent
- [ ] Open `lib/jido_code_core/agent/code_session.ex`
- [ ] Add `on_init/2` callback

```elixir
def on_init(agent, opts) do
  params = Keyword.get(opts, :params, %{})
  initial_state = StateInitializer.init(params)
  {agent, initial_state}
end
```

### 6.2.2.2: Add Pre-init Validation
- [ ] Validate session parameters
- [ ] Check project path exists
- [ ] Verify configuration

### 6.2.2.3: Create Initialization Tests
- [ ] Test state initialization
- [ ] Test validation
- [ ] Verify defaults apply

---

## Phase 6.2 Success Criteria

1. **Initializer**: State initializer created
2. **Validation**: All fields validate correctly
3. **Callbacks**: Init callbacks working
4. **Tests**: Initialization tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/agent/state_initializer.ex` | ~100 (new) | Initializer |
| `lib/jido_code_core/agent/code_session.ex` | ~40 | Add callbacks |
| `test/jido_code_core/agent/state_initializer_test.exs` | ~100 (new) | Tests |

## Rollback Plan

```bash
rm -f lib/jido_code_core/agent/state_initializer.ex
git checkout lib/jido_code_core/agent/code_session.ex
rm -f test/jido_code_core/agent/state_initializer_test.exs
```

Proceed to [Section 6.3: Session API](./03-api-compatibility.md)
