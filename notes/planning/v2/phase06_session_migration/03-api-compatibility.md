# Phase 6.3: API Compatibility Layer

Maintain backward compatibility for existing Session APIs.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      API Compatibility Layer                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                   Client Code                             │  │
│   │  Session.State.get_state(session_id)                     │  │
│   │  Session.State.append_message(session_id, msg)           │  │
│   └─────────────────────────────────────────────────────────┘  │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              Session.State (Compat Layer)                │  │
│   │  Detect mode → Route to AgentServer or GenServer         │  │
│   └─────────────────────────────────────────────────────────┘  │
│          │                              │                        │
│          ├── Agent Mode ──────────────┼── GenServer Mode       │
│          │                              │                        │
│          ▼                              ▼                        │
│   ┌──────────────┐              ┌──────────────┐                │
│   │ AgentServer  │              │ Session.State │                │
│   │ (new path)   │              │ (legacy)      │                │
│   └──────────────┘              └──────────────┘                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/session/state.ex` | Add compatibility layer |
| `lib/jido_code_core/api/session.ex` | Update client API |

---

## 6.3.1: Create Session API Adapter

Wrap AgentServer in Session.State-compatible API.

### 6.3.1.1: Add Mode Detection
- [ ] Open `lib/jido_code_core/session/state.ex`
- [ ] Add `agent_mode?/0` function

```elixir
defp agent_mode? do
  Application.get_env(:jido_code_core, :agent_mode, false)
end
```

### 6.3.1.2: Add Routing Functions
- [ ] Route `get_state/1` to appropriate backend
- [ ] Route `append_message/2` to appropriate backend
- [ ] Route all public functions

```elixir
def get_state(session_id) do
  if agent_mode?() do
    # New path: Query AgentServer
    case Jido.Agent.Server.whereis(session_id) do
      {:ok, pid} ->
        Jido.Agent.Server.get_state(pid)

      {:error, :not_found} ->
        {:error, :not_found}
    end
  else
    # Legacy path: Query GenServer
    call_state(session_id, :get_state)
  end
end
```

### 6.3.1.3: Add Deprecation Warnings
- [ ] Log deprecation notices for legacy mode
- [ ] Provide migration guidance
- [ ] Add warning suppression option

---

## 6.3.2: Maintain All Existing APIs

Ensure no breaking changes for existing clients.

### 6.3.2.1: Update get_state/1
- [ ] Route to AgentServer in agent mode
- [ ] Maintain legacy path
- [ ] Return same format

### 6.3.2.2: Update get_messages/1
- [ ] Route to AgentServer in agent mode
- [ ] Maintain pagination
- [ ] Return same format

### 6.3.2.3: Update append_message/2
- [ ] Route to AgentServer in agent mode
- [ ] Convert to signal
- [ ] Return same result format

### 6.3.2.4: Update update_todos/2
- [ ] Route to AgentServer in agent mode
- [ ] Convert to StateOps
- [ ] Return same result format

### 6.3.2:5: Update All State Access Functions
- [ ] get_reasoning_steps/1
- [ ] get_todos/1
- [ ] get_tool_calls/1
- [ ] get_prompt_history/1
- [ ] get_context/2
- [ ] file_was_read?/2
- [ ] etc.

---

## 6.3.3: Add Feature Flag Support

Enable gradual rollout of Agent mode.

### 6.3.3.1: Add Runtime Flag
- [ ] Support config changes at runtime
- [ ] Add flag toggle endpoint
- [ ] Handle flag changes gracefully

### 6.3.3.2: Add Per-Session Flag
- [ ] Support agent mode per session
- [ ] Add session-level override
- [ ] Document flag precedence

### 6.3.3.3: Create Compatibility Tests
- [ ] Test both modes with same inputs
- [ ] Verify identical outputs
- [ ] Test mode switching

---

## Phase 6.3 Success Criteria

1. **Compatibility**: All APIs work in both modes
2. **Routing**: Correct routing to backend
3. **Deprecation**: Warnings logged for legacy
4. **Feature Flag**: Can toggle between modes
5. **Tests**: All compatibility tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/session/state.ex` | ~200 | Add compatibility |
| `lib/jido_code_core/api/session.ex` | ~100 | Update client API |
| `test/jido_code_core/session/compatibility_test.exs` | ~200 | Tests |

## Rollback Plan

```bash
git checkout lib/jido_code_core/session/state.ex
git checkout lib/jido_code_core/api/session.ex
rm -f test/jido_code_core/session/compatibility_test.exs
```

## Phase 6 Success Criteria

1. **AgentServer**: CodeSessionAgentServer running
2. **Migration**: State data migrates correctly
3. **Compatibility**: Existing APIs still work
4. **Feature Flag**: Can toggle between modes
5. **Tests**: All session tests pass

Proceed to [Phase 7: Memory System](../phase07_memory_system/overview.md)
