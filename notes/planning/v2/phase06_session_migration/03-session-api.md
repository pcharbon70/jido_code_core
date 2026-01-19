# Phase 6.3: Session API

Implement the Session client API.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Session API Layer                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                   Client Code                             │  │
│   │  Session.get_state(session_id)                           │  │
│   │  Session.append_message(session_id, msg)                 │  │
│   └─────────────────────────────────────────────────────────┘  │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              Session API                                 │  │
│   │  • Query AgentServer                                     │  │
│   │  • Format responses                                      │  │
│   └─────────────────────────────────────────────────────────┘  │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              AgentServer                                 │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/api/session.ex` | Session client API |
| `lib/jido_code_core/agent/server.ex` | Server queries |

---

## 6.3.1: Create Session API Module

Implement client API for session operations.

### 6.3.1.1: Create Session API Module
- [ ] Create `lib/jido_code_core/api/session.ex`

```elixir
defmodule JidoCodeCore.API.Session do
  @moduledoc """
  Client API for session operations.
  """

  alias JidoCodeCore.Agent.Server
  alias JidoCodeCore.Agent.CodeSession

  @doc """
  Get session state.
  """
  def get_state(session_id) do
    case Server.whereis(session_id) do
      {:ok, pid} ->
        Server.get_state(pid)

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @doc """
  Append message to session.
  """
  def append_message(session_id, message) do
    # Implementation
  end

  # ... other API functions
end
```

### 6.3.1.2: Add State Query Functions
- [ ] `get_state/1`
- [ ] `get_messages/1`
- [ ] `get_reasoning_steps/1`
- [ ] `get_todos/1`
- [ ] `get_tool_calls/1`

### 6.3.1.3: Add State Update Functions
- [ ] `append_message/2`
- [ ] `update_todos/2`
- [ ] `set_config/2`

### 6.3.1.4: Add Session Lifecycle Functions
- [ ] `start_session/1`
- [ ] `stop_session/1`
- [ ] `list_sessions/0`

---

## 6.3.2: Add Signal-Based Operations

Implement operations via signals.

### 6.3.2.1: Create Signal Helpers
- [ ] `send_signal/2`
- [ ] `query_state/2`
- [ ] `await_result/2`

### 6.3.2.2: Add Async Operations
- [ ] `append_message_async/2`
- [ ] `execute_tool_async/2`
- [ ] Handle async results

---

## 6.3.3: Create API Tests

Test the Session API.

### 6.3.3.1: Test Query Functions
- [ ] Test `get_state/1`
- [ ] Test `get_messages/1`
- [ ] Test error handling

### 6.3.3.2: Test Update Functions
- [ ] Test `append_message/2`
- [ ] Test `update_todos/2`
- [ ] Verify state updates

### 6.3.3.3: Test Lifecycle Functions
- [ ] Test `start_session/1`
- [ ] Test `stop_session/1`
- [ ] Test `list_sessions/0`

---

## Phase 6.3 Success Criteria

1. **API**: All API functions implemented
2. **Queries**: State queries working
3. **Updates**: State updates working
4. **Tests**: All API tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/api/session.ex` | ~200 (new) | Session API |
| `test/jido_code_core/api/session_test.exs` | ~250 (new) | Tests |

## Rollback Plan

```bash
rm -f lib/jido_code_core/api/session.ex
rm -f test/jido_code_core/api/session_test.exs
```

## Phase 6 Success Criteria

1. **AgentServer**: CodeSessionAgentServer running
2. **State**: Session state initializes correctly
3. **API**: Session API functional
4. **Tests**: All session tests pass

Proceed to [Phase 7: Memory System](../phase07_memory_system/overview.md)
