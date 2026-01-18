# Phase 2.2: StateOps Migration

Replace direct state mutations with StateOp patterns.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   StateOp Pattern Mapping                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Current Pattern (GenServer)        Target Pattern (StateOps)   │
│   ────────────────────────────        ─────────────────────────  │
│                                                                  │
│   handle_call({:update_todos,        %StateOp.SetState{          │
│     todos}, _from, state) do          attrs: %{todos: todos}}     │
│     new_state = %{state │                                        │
│       todos: todos}                   Applied by:                  │
│     {:reply, {:ok, new_state},         StateOps.apply_state_ops/2 │
│      new_state}                                                    │
│   end                                                             │
│                                                                  │
│   handle_call({:add_todo, todo}    %StateOp.SetPath{             │
│     new_state = put_in(              path: [:todos],              │
│       state, [:todos], todo)          value: todo}                │
│   end                                                             │
│                                                                  │
│   handle_call({:delete_file,       %StateOp.DeletePath{          │
│     path}, state) do                 path: [:files, path]}        │
│     new_state = update_in(                                       │
│       state, [:files], &Map.delete/2)                            │
│   end                                                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/agent/state_ops_map.ex` | StateOp mapping documentation |
| `lib/jido_code_core/agent/session_state_ops.ex` | StateOp builder functions |

---

## 2.2.1: Map Current State Changes to StateOps

Document all current state mutation patterns.

### 2.2.1.1: Audit Session.State handle_call Patterns
- [ ] Read `/home/ducky/code/agentjido/jido_code_core/lib/jido_code_core/session/state.ex`
- [ ] Identify all `handle_call` patterns that modify state
- [ ] Document each mutation pattern:

| Current Pattern | StateOp Equivalent | Notes |
|-----------------|-------------------|-------|
| `%{state | todos: todos}` | `SetState{attrs: %{todos: todos}}` | Direct replacement |
| `update_in(state, [:messages])` | `SetPath{path: [:messages]}` | Nested update |
| `Map.delete(state.files, path)` | `DeletePath{path: [:files, path]}` | Nested delete |
| `[msg \| state.messages]` | Custom function in SetState | List prepend |

### 2.2.1.2: Create StateOps Mapping Module
- [ ] Create `lib/jido_code_core/agent/state_ops_map.ex`
- [ ] Document all migration mappings
- [ ] Add before/after examples for each pattern

### 2.2.1.3: Verify StateOp Availability
- [ ] Verify `Jido.Agent.StateOp.SetState` exists
- [ ] Verify `Jido.Agent.StateOp.ReplaceState` exists
- [ ] Verify `Jido.Agent.StateOp.DeleteKeys` exists
- [ ] Verify `Jido.Agent.StateOp.SetPath` exists
- [ ] Verify `Jido.Agent.StateOp.DeletePath` exists

---

## 2.2.2: Create StateOp Builders for Session

Build helper functions for common session state operations.

### 2.2.2.1: Create SessionStateOps Module
- [ ] Create `lib/jido_code_core/agent/session_state_ops.ex`
- [ ] Add `import Jido.Agent.StateOp` directive

### 2.2.2.2: Add Message StateOps
- [ ] `append_message/1` - Append message to list
- [ ] `prepend_message/1` - Prepend message to list
- [ ] `clear_messages/0` - Clear all messages
- [ ] `set_messages/1` - Replace entire message list

```elixir
def append_message(message) do
  %SetState{attrs: %{messages: fn current -> [message | current] end}}
end

def prepend_message(message) do
  %SetState{attrs: %{messages: fn current -> current ++ [message] end}}
end
```

### 2.2.2.3: Add Todo StateOps
- [ ] `add_todo/1` - Add a todo
- [ ] `update_todos/1` - Replace entire todo list
- [ ] `complete_todo/1` - Mark todo as completed
- [ ] `remove_todo/1` - Remove a todo

### 2.2.2.4: Add File Tracking StateOps
- [ ] `track_file_read/1` - Record file read
- [ ] `track_file_write/1` - Record file write
- [ ] `clear_file_tracking/0` - Clear all tracking

### 2.2.2.5: Add Tool Call StateOps
- [ ] `add_tool_call/1` - Add tool call record
- [ ] `update_tool_call/2` - Update tool call result
- [ ] `clear_tool_calls/0` - Clear all tool calls

### 2.2.2.6: Add Context StateOps
- [ ] `update_context/2` - Update working context item
- [ ] `clear_context/0` - Clear working context
- [ ] `set_context/1` - Replace entire context

### 2.2.2.7: Create StateOp Tests
- [ ] Test each StateOp builder
- [ ] Verify StateOps apply correctly
- [ ] Test with StateOps.apply_state_ops/2

---

## Phase 2.2 Success Criteria

1. **Mapping**: All state mutations mapped to StateOps
2. **Builders**: SessionStateOps provides all necessary builders
3. **Tests**: StateOp tests pass
4. **Documentation**: Migration patterns documented
5. **Compatibility**: StateOps produce equivalent results

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/agent/state_ops_map.ex` | ~100 (new) | Mapping docs |
| `lib/jido_code_core/agent/session_state_ops.ex` | ~200 (new) | StateOp builders |
| `test/jido_code_core/agent/session_state_ops_test.exs` | ~150 (new) | Tests |

## Rollback Plan

```bash
rm -f lib/jido_code_core/agent/state_ops_map.ex
rm -f lib/jido_code_core/agent/session_state_ops.ex
rm -f test/jido_code_core/agent/session_state_ops_test.exs
```

Proceed to [Section 2.3: Directive Migration](./03-directive-migration.md)
