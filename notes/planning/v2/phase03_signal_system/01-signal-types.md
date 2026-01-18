# Phase 3.1: Signal Types

Complete signal type definitions for all JidoCodeCore events.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Signal Type Hierarchy                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Jido.Signal (CloudEvents)                                      │
│        │                                                         │
│        ├─── Tool Signals                                         │
│        │    ├─── ToolCall                                        │
│        │    ├─── ToolResult                                      │
│        │    └─── ToolError                                       │
│        │                                                         │
│        ├─── Memory Signals                                       │
│        │    ├─── MemoryStored                                    │
│        │    ├─── MemoryRecalled                                  │
│        │    ├─── MemoryForgotten                                 │
│        │    └─── MemoryPromoted                                  │
│        │                                                         │
│        ├─── File Signals                                         │
│        │    ├─── FileRead                                        │
│        │    ├─── FileWrite                                       │
│        │    └─── FileList                                        │
│        │                                                         │
│        └─── Session Signals                                      │
│             ├─── MessageAppended                                 │
│             ├─── StateChanged                                    │
│             └─── ConfigUpdated                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/signals.ex` | All signal type definitions |

---

## 3.1.1: Define Memory System Signals

Create signals for all memory-related events.

### 3.1.1.1: Define MemoryStored Signal
- [ ] Type: `"jido_code.memory.stored"`
- [ ] Data: memory_id, content, memory_type, confidence
- [ ] Source: `/jido_code/memory/{session_id}`

```elixir
defmodule JidoCodeCore.Signals.MemoryStored do
  use Jido.Signal,
    type: "jido_code.memory.stored",
    default_source: "/jido_code/memory",
    schema: [
      memory_id: [type: :string, required: true],
      content: [type: :string, required: true],
      memory_type: [type: :atom, required: true],
      confidence: [type: :float, default: 0.5],
      session_id: [type: :string, required: true]
    ]
end
```

### 3.1.1.2: Define MemoryRecalled Signal
- [ ] Type: `"jido_code.memory.recalled"`
- [ ] Data: query, results, count
- [ ] Source: `/jido_code/memory/{session_id}`

### 3.1.1.3: Define MemoryForgotten Signal
- [ ] Type: `"jido_code.memory.forgotten"`
- [ ] Data: memory_id, reason
- [ ] Source: `/jido_code/memory/{session_id}`

### 3.1.1.4: Define MemoryPromoted Signal
- [ ] Type: `"jido_code.memory.promoted"`
- [ ] Data: memory_ids, count
- [ ] Source: `/jido_code/memory/{session_id}`

---

## 3.1.2: Define File System Signals

Create signals for file system operations.

### 3.1.2.1: Define FileRead Signal
- [ ] Type: `"jido_code.file.read"`
- [ ] Data: path, size, lines
- [ ] Source: `/jido_code/file/{session_id}`

```elixir
defmodule JidoCodeCore.Signals.FileRead do
  use Jido.Signal,
    type: "jido_code.file.read",
    default_source: "/jido_code/file",
    schema: [
      path: [type: :string, required: true],
      size: [type: :integer],
      lines: [type: :integer],
      session_id: [type: :string, required: true]
    ]
end
```

### 3.1.2.2: Define FileWrite Signal
- [ ] Type: `"jido_code.file.write"`
- [ ] Data: path, size, lines
- [ ] Source: `/jido_code/file/{session_id}`

### 3.1.2.3: Define FileList Signal
- [ ] Type: `"jido_code.file.list"`
- [ ] Data: path, entries
- [ ] Source: `/jido_code/file/{session_id}`

---

## 3.1.3: Define Session Signals

Create signals for session state changes.

### 3.1.3.1: Define MessageAppended Signal
- [ ] Type: `"jido_code.session.message"`
- [ ] Data: message_id, role, content
- [ ] Source: `/jido_code/session/{session_id}`

```elixir
defmodule JidoCodeCore.Signals.MessageAppended do
  use Jido.Signal,
    type: "jido_code.session.message",
    default_source: "/jido_code/session",
    schema: [
      message_id: [type: :string, required: true],
      role: [type: :atom, required: true],
      content: [type: :string, required: true],
      timestamp: [type: :struct, required: true],
      session_id: [type: :string, required: true]
    ]
end
```

### 3.1.3.2: Define StateChanged Signal
- [ ] Type: `"jido_code.session.state_changed"`
- [ ] Data: field, old_value, new_value
- [ ] Source: `/jido_code/session/{session_id}`

### 3.1.3.3: Define ConfigUpdated Signal
- [ ] Type: `"jido_code.session.config"`
- [ ] Data: config changes
- [ ] Source: `/jido_code/session/{session_id}`

---

## 3.1.4: Create Signal Tests

Test all signal types.

### 3.1.4.1: Test Memory Signals
- [ ] Test MemoryStored signal creation
- [ ] Test MemoryRecalled signal creation
- [ ] Test MemoryForgotten signal creation
- [ ] Test MemoryPromoted signal creation

### 3.1.4.2: Test File Signals
- [ ] Test FileRead signal creation
- [ ] Test FileWrite signal creation
- [ ] Test FileList signal creation

### 3.1.4.3: Test Session Signals
- [ ] Test MessageAppended signal creation
- [ ] Test StateChanged signal creation
- [ ] Test ConfigUpdated signal creation

### 3.1.4.4: Test CloudEvents Compliance
- [ ] Verify all signals have required CloudEvents fields
- [ ] Test type field format
- [ ] Test source field format
- [ ] Test data field structure

---

## Phase 3.1 Success Criteria

1. **Memory Signals**: All memory signal types defined
2. **File Signals**: All file signal types defined
3. **Session Signals**: All session signal types defined
4. **Validation**: All signals validate correctly
5. **CloudEvents**: All signals CloudEvents-compliant
6. **Tests**: All signal tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/signals.ex` | +200 | Add all signal types |
| `test/jido_code_core/signals_test.exs` | +200 | Add signal tests |

## Rollback Plan

```bash
git checkout lib/jido_code_core/signals.ex
git checkout test/jido_code_core/signals_test.exs
```

Proceed to [Section 3.2: Signal Routing](./02-signal-routing.md)
