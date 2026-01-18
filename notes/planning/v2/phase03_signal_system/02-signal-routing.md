# Phase 3.2: Signal Routing

Establish signal routing patterns for CodeSessionAgent.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Signal Routing Flow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Incoming Signal                                                │
│        │                                                         │
│        ▼                                                         │
│   ┌─────────────┐                                               │
│   │ Pattern     │                                               │
│   │ Matching    │                                               │
│   └──────┬──────┘                                               │
│          │                                                       │
│          ├─── "jido_code.tool.call" ──> ExecuteTool Action       │
│          │                                                       │
│          ├─── "jido_code.memory.*" ───> HandleMemory Action      │
│          │                                                       │
│          ├─── "jido_code.file.*" ────> HandleFile Action        │
│          │                                                       │
│          └─── "jido_code.session.*" ─> HandleSession Action     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/agent/code_session.ex` | Add signal routing |
| `lib/jido_code_core/actions/` | Create action handlers |

---

## 3.2.1: Define Signal Routes

Add routing configuration to CodeSessionAgent.

### 3.2.1.1: Add signal_routes/0 to CodeSessionAgent
- [ ] Open `lib/jido_code_core/agent/code_session.ex`
- [ ] Add signal_routes/0 function

```elixir
def signal_routes do
  [
    # Tool signals
    {"jido_code.tool.call", JidoCodeCore.Actions.ExecuteTool},
    {"jido_code.tool.result", JidoCodeCore.Actions.ProcessToolResult},
    {"jido_code.tool.error", JidoCodeCore.Actions.HandleToolError},

    # Memory signals
    {"jido_code.memory.stored", JidoCodeCore.AcknowledgeMemory},
    {"jido_code.memory.recalled", JidoCodeCore.AcknowledgeMemory},
    {"jido_code.memory.*", JidoCodeCore.Actions.HandleMemory},

    # File signals
    {"jido_code.file.read", JidoCodeCore.Actions.TrackFileRead},
    {"jido_code.file.write", JidoCodeCore.Actions.TrackFileWrite},

    # Session signals
    {"jido_code.session.message", JidoCodeCore.Actions.AppendMessage},
    {"jido_code.session.state_changed", JidoCodeCore.Actions.UpdateState}
  ]
end
```

### 3.2.1.2: Test Wildcard Pattern Matching
- [ ] Test that `"jido_code.memory.*"` matches all memory signals
- [ ] Test that specific patterns match exactly
- [ ] Test that unknown patterns return no match

---

## 3.2.2: Create Tool Handler Actions

Create actions that handle tool-related signals.

### 3.2.2.1: Create ExecuteTool Action
- [ ] Create `lib/jido_code_core/actions/execute_tool.ex`
- [ ] Handle `jido_code.tool.call` signals
- [ ] Return StateOps for tracking
- [ ] Return Directive.Emit for result

```elixir
defmodule JidoCodeCore.Actions.ExecuteTool do
  use Jido.Action,
    name: "execute_tool",
    description: "Handle tool execution from signal"

  def run(%{tool_name: name, params: params, call_id: call_id}, context) do
    # Execute tool and return StateOps + Directives
    # This will integrate with existing Tools.Executor
  end
end
```

### 3.2.2.2: Create ProcessToolResult Action
- [ ] Create `lib/jido_code_core/actions/process_tool_result.ex`
- [ ] Handle `jido_code.tool.result` signals
- [ ] Update tool call tracking state

### 3.2.2.3: Create HandleToolError Action
- [ ] Create `lib/jido_code_core/actions/handle_tool_error.ex`
- [ ] Handle `jido_code.tool.error` signals
- [ ] Update tool call with error status

---

## 3.2.3: Create Memory Handler Actions

Create actions that handle memory-related signals.

### 3.2.3.1: Create HandleMemory Action
- [ ] Create `lib/jido_code_core/actions/handle_memory.ex`
- [ ] Handle all memory wildcard signals
- [ ] Route to specific memory actions based on type

### 3.2.3.2: Create AcknowledgeMemory Action
- [ ] Create `lib/jido_code_core/actions/acknowledge_memory.ex`
- [ ] Handle memory stored/recalled/forgotten signals
- [ ] Update tracking state

---

## 3.2.4: Create File Handler Actions

Create actions that handle file-related signals.

### 3.2.4.1: Create TrackFileRead Action
- [ ] Create `lib/jido_code_core/actions/track_file_read.ex`
- [ ] Handle `jido_code.file.read` signals
- [ ] Update file_reads tracking

### 3.2.4.2: Create TrackFileWrite Action
- [ ] Create `lib/jido_code_core/actions/track_file_write.ex`
- [ ] Handle `jido_code.file.write` signals
- [ ] Update file_writes tracking

---

## Phase 3.2 Success Criteria

1. **Routes**: Signal routes defined in CodeSessionAgent
2. **Actions**: Tool handler actions created
3. **Memory**: Memory handler actions created
4. **Files**: File handler actions created
5. **Tests**: All routing tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/agent/code_session.ex` | +50 | Add signal routes |
| `lib/jido_code_core/actions/execute_tool.ex` | ~100 (new) | Tool action |
| `lib/jido_code_core/actions/process_tool_result.ex` | ~80 (new) | Result action |
| `lib/jido_code_core/actions/handle_tool_error.ex` | ~60 (new) | Error action |
| `lib/jido_code_core/actions/handle_memory.ex` | ~80 (new) | Memory action |
| `lib/jido_code_core/actions/track_file_read.ex` | ~60 (new) | File read action |
| `lib/jido_code_core/actions/track_file_write.ex` | ~60 (new) | File write action |

## Rollback Plan

```bash
git checkout lib/jido_code_core/agent/code_session.ex
rm -f lib/jido_code_core/actions/execute_tool.ex
rm -f lib/jido_code_core/actions/process_tool_result.ex
rm -f lib/jido_code_core/actions/handle_tool_error.ex
rm -f lib/jido_code_core/actions/handle_memory.ex
rm -f lib/jido_code_core/actions/track_file_read.ex
rm -f lib/jido_code_core/actions/track_file_write.ex
```

Proceed to [Section 3.3: PubSub Bridge](./03-pubsub-bridge.md)
