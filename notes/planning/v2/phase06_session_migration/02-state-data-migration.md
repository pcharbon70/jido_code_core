# Phase 6.2: State Data Migration

Migrate existing session state to Agent format.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   State Migration Flow                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────┐     migrate     ┌─────────────────┐       │
│   │ Session.State    │────────────────>│ Agent State     │       │
│   │ (GenServer)      │                 │ (pure data)     │       │
│   └─────────────────┘                 └─────────────────┘       │
│          │                                      │                │
│          │ messages, reasoning_steps,         │                │
│          │ tool_calls, todos,                 │                │
│          │ file_reads, file_writes            │                │
│          │                                      │                │
│          ▼                                      ▼                │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              State Migrator                               │  │
│   │  • Transform field names                                  │  │
│   │  • Convert data structures                                │  │
│   │  • Validate migrated state                                │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/migration/state_migrator.ex` | State migration logic |
| `lib/jido_code_core/session/manager.ex` | Migration hooks |

---

## 6.2.1: Create State Migrator

Build migrator from Session.State to Agent state.

### 6.2.1.1: Create StateMigrator Module
- [ ] Create `lib/jido_code_core/migration/` directory
- [ ] Create `state_migrator.ex`

```elixir
defmodule JidoCodeCore.Migration.StateMigrator do
  @moduledoc """
  Migrate session state from Session.State to Agent format.
  """

  alias JidoCodeCore.Session
  alias JidoCodeCore.Agent.Converters

  @doc """
  Migrate a Session struct to Agent state map.
  """
  def migrate(%Session{} = session) do
    Converters.session_to_agent(session)
  end

  @doc """
  Migrate a Session.State process state to Agent state map.
  """
  def migrate_process_state(process_state) when is_map(process_state) do
    %{
      session_id: process_state.session_id,
      project_path: process_state.session.project_root,
      language: process_state.session.language,
      messages: Enum.reverse(process_state.messages),
      reasoning_steps: Enum.reverse(process_state.reasoning_steps),
      tool_calls: Enum.reverse(process_state.tool_calls),
      todos: process_state.todos,
      file_reads: process_state.file_reads,
      file_writes: process_state.file_writes,
      llm_config: session_to_llm_config(process_state.session),
      working_context: process_state.working_context,
      pending_memories: process_state.pending_memories,
      access_log: process_state.access_log,
      created_at: process_state.session.created_at,
      updated_at: process_state.session.updated_at
    }
  end
end
```

### 6.2.1.2: Add Validation
- [ ] Validate migrated state structure
- [ ] Check for missing fields
- [ ] Handle edge cases

### 6.2.1.3: Add Error Handling
- [ ] Handle invalid input states
- [ ] Provide clear error messages
- [ ] Log migration failures

---

## 6.2.2: Add Runtime Migration Hook

Auto-migrate sessions on access.

### 6.2.2.1: Update Session.Manager
- [ ] Open `lib/jido_code_core/session/manager.ex`
- [ ] Add migration trigger on session access

```elixir
def get_session(session_id) do
  case locate_session(session_id) do
    {:ok, :agent_mode, agent} ->
      # Already in Agent mode
      {:ok, agent}

    {:ok, :gen_server_mode, state_pid} ->
      # Migrate to Agent mode
      migrate_to_agent(session_id, state_pid)

    {:error, :not_found} ->
      {:error, :not_found}
  end
end
```

### 6.2.2.2: Add Migration Caching
- [ ] Cache migration results
- [ ] Prevent duplicate migrations
- [ ] Add cache invalidation

### 6.2.2.3: Create Migration Tests
- [ ] Test state migration
- [ ] Test runtime migration hook
- [ ] Verify no data loss

---

## Phase 6.2 Success Criteria

1. **Migrator**: State migrator created
2. **Validation**: All fields validate correctly
3. **Runtime Hook**: Migrations trigger automatically
4. **Caching**: Migration results cached
5. **Tests**: Migration tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/migration/state_migrator.ex` | ~200 (new) | Migrator |
| `lib/jido_code_core/session/manager.ex` | ~80 | Add hooks |
| `test/jido_code_core/migration/state_migrator_test.exs` | ~150 (new) | Tests |

## Rollback Plan

```bash
rm -rf lib/jido_code_core/migration/
git checkout lib/jido_code_core/session/manager.ex
```

Proceed to [Section 6.3: API Compatibility](./03-api-compatibility.md)
