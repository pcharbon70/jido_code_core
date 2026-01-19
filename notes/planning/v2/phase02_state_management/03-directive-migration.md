# Phase 2.3: Directive Migration

Replace Phoenix.PubSub broadcasts with Directive.Emit patterns.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  Directive Migration Pattern                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Current Pattern (PubSub)          Target Pattern (Directive)   │
│   ────────────────────────────        ─────────────────────────  │
│                                                                  │
│   Phoenix.PubSub.broadcast(         Directive.emit(              │
│     @pubsub,                        Signal.new!(                  │
│     "tui.events.#{session_id}",       "tool.call",                │
│     {:tool_call, name,               %{tool: name},              │
│      params, call_id})               source: "/session"           │
│                                      ),                           │
│                                      {:pubsub, topic: "..."}     │
│                                    )                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/signals.ex` | Signal type definitions |
| `lib/jido_code_core/agent/directive_builders.ex` | Directive builders |

---

## 2.3.1: Audit Current PubSub Usage

Document all current PubSub event patterns.

### 2.3.1.1: Find All PubSub Broadcasts
- [ ] Search for `Phoenix.PubSub.broadcast` calls
- [ ] Search for `PubSubHelpers.broadcast` calls
- [ ] Document all event types and payloads

### 2.3.1.2: Document Event Types
- [ ] `{:tool_call, tool_name, params, call_id, session_id}`
- [ ] `{:tool_result, result, session_id}`
- [ ] `{:streaming_chunk, chunk, session_id}`
- [ ] `{:state_change, field, value, session_id}`

### 2.3.1.3: Create PubSub Mapping Document
- [ ] Map each PubSub event to Jido.Signal type
- [ ] Document payload transformations needed
- [ ] Create in `notes/research/pubsub_mapping.md`

---

## 2.3.2: Create Signal Types for Session

Define CloudEvents-compliant signals for all session events.

### 2.3.2.1: Create Signals Module
- [ ] Create `lib/jido_code_core/signals.ex`
- [ ] Add `use Jido.Signal` for each signal type

### 2.3.2.2: Define ToolCallSignal
- [ ] Type: `"jido_code.tool.call"`
- [ ] Data: tool_name, params, call_id, session_id
- [ ] Source: `/jido_code/session/{session_id}`

```elixir
defmodule JidoCodeCore.Signals.ToolCall do
  use Jido.Signal,
    type: "jido_code.tool.call",
    default_source: "/jido_code/session",
    schema: [
      tool_name: [type: :string, required: true],
      params: [type: :map, required: true],
      call_id: [type: :string, required: true],
      session_id: [type: :string, required: true]
    ]
end
```

### 2.3.2.3: Define ToolResultSignal
- [ ] Type: `"jido_code.tool.result"`
- [ ] Data: call_id, tool_name, result, duration_ms
- [ ] Source: `/jido_code/session/{session_id}`

### 2.3.2.4: Define MessageSignal
- [ ] Type: `"jido_code.message.append"`
- [ ] Data: message_id, role, content, timestamp
- [ ] Source: `/jido_code/session/{session_id}`

### 2.3.2.5: Define StateChangeSignal
- [ ] Type: `"jido_code.state.change"`
- [ ] Data: field, old_value, new_value
- [ ] Source: `/jido_code/session/{session_id}`

### 2.3.2.6: Create Signal Tests
- [ ] Test signal creation and validation
- [ ] Verify CloudEvents format compliance
- [ ] Test required fields

---

## 2.3.3: Create Directive.Emit Builders

Build helper functions for common directive emissions.

### 2.3.3.1: Create DirectiveBuilders Module
- [ ] Create `lib/jido_code_core/agent/directive_builders.ex`
- [ ] Add `import Jido.Agent.Directive`

### 2.3.3.2: Add Tool Call Builders
- [ ] `emit_tool_call/4` - Emit tool call signal
- [ ] `emit_tool_result/2` - Emit tool result signal
- [ ] `emit_tool_error/3` - Emit tool error signal

```elixir
def emit_tool_call(tool_name, params, call_id, session_id) do
  signal = Signals.ToolCall.new!(%{
    tool_name: tool_name,
    params: params,
    call_id: call_id,
    session_id: session_id
  }, source: "/jido_code/session/#{session_id}")

  Directive.emit(signal, {:pubsub, topic: "tui.events.#{session_id}"})
end
```

### 2.3.3.3: Add Message Builders
- [ ] `emit_message_append/2` - Emit message append signal
- [ ] `emit_message_clear/1` - Emit message clear signal

### 2.3.3.4: Add State Change Builders
- [ ] `emit_state_change/4` - Emit state change signal
- [ ] `emit_config_change/3` - Emit config change signal

### 2.3.3.5: Create Directive Tests
- [ ] Test directive builders
- [ ] Verify signals are created correctly
- [ ] Test pubsub adapter receives directives

---

## Phase 2.3 Success Criteria

1. **Audit**: All PubSub events documented
2. **Signals**: All signal types defined and validated
3. **Builders**: Directive builders working
4. **Tests**: Signal and directive tests pass
5. **CloudEvents**: All signals CloudEvents-compliant

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/signals.ex` | ~150 (new) | Signal definitions |
| `lib/jido_code_core/agent/directive_builders.ex` | ~200 (new) | Directive builders |
| `test/jido_code_core/signals_test.exs` | ~100 (new) | Signal tests |
| `test/jido_code_core/agent/directive_builders_test.exs` | ~150 (new) | Builder tests |

## Rollback Plan

```bash
rm -f lib/jido_code_core/signals.ex
rm -f lib/jido_code_core/agent/directive_builders.ex
rm -f test/jido_code_core/signals_test.exs
rm -f test/jido_code_core/agent/directive_builders_test.exs
```

## Phase 2 Success Criteria

1. **Agent**: CodeSessionAgent compiles and runs
2. **StateOps**: State mutations use StateOp patterns
3. **Directives**: Side effects use Directive.Emit
4. **Tests**: All tests pass
5. **Performance**: No performance regression

Proceed to [Phase 3: Signal System](../phase03_signal_system/overview.md)
