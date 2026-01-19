# Phase 1.2: Error Handling

Implement Splode-based structured error handling.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Error Handling Flow                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────┐     ┌─────────────┐     ┌────────────┐  │
│   │ Application │────>│ Errors      │────>│ Splode     │  │
│   │ Code        │     │ Module      │     │ Errors     │  │
│   └─────────────┘     └─────────────┘     └────────────┘  │
│         │                                       │          │
│         v                                       v          │
│   ┌────────────────────────────────────────────────────┐  │
│   │         Structured Error Interface                 │  │
│   │  raise JidoCodeCore.Errors.SomeError.exception()  │  │
│   └────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/errors.ex` | Error module with Splode setup |
| `lib/jido_code_core/errors/*.ex` | Individual error classes |

---

## 1.2.1: Audit Current Error Patterns

Document existing error patterns for Splode migration.

### 1.2.1.1: Review Existing Error Module
- [ ] Read `/home/ducky/code/agentjido/jido_code_core/lib/jido_code_core/error.ex`
- [ ] Document all custom error types defined
- [ ] Identify all error return patterns

### 1.2.1.2: Identify Error Patterns
- [ ] Search for `{:error, reason}` patterns in codebase
- [ ] Document all unique error reason atoms
- [ ] Identify error locations in:
  - `lib/jido_code_core/tools/executor.ex`
  - `lib/jido_code_core/session/state.ex`
  - `lib/jido_code_core/memory/`

### 1.2.1.3: Create Error Documentation
- [ ] Document all error types in `notes/research/error_patterns.md`
- [ ] Map current errors to Splode equivalents

---

## 1.2.2: Implement Splode Error Handling

Add Splode-based error handling.

### 1.2.2.1: Create Error Module Structure
- [ ] Create `lib/jido_code_core/errors.ex` with Splode setup:

```elixir
defmodule JidoCodeCore.Errors do
  use Splode, error_classes: [
    session: JidoCodeCore.Errors.Session,
    tools: JidoCodeCore.Errors.Tools,
    memory: JidoCodeCore.Errors.Memory,
    validation: JidoCodeCore.Errors.Validation,
    agent: JidoCodeCore.Errors.Agent
  ]
end
```

### 1.2.2.2: Create Session Error Class
- [ ] Create `lib/jido_code_core/errors/session.ex`
- [ ] Define `SessionNotFound` error
- [ ] Define `SessionInvalidState` error
- [ ] Define `SessionConfigError` error

### 1.2.2.3: Create Tools Error Class
- [ ] Create `lib/jido_code_core/errors/tools.ex`
- [ ] Define `ToolNotFound` error
- [ ] Define `ToolExecutionFailed` error
- [ ] Define `ToolTimeout` error
- [ ] Define `ToolValidationFailed` error

### 1.2.2.4: Create Memory Error Class
- [ ] Create `lib/jido_code_core/errors/memory.ex`
- [ ] Define `MemoryNotFound` error
- [ ] Define `MemoryStorageFailed` error
- [ ] Define `MemoryPromotionFailed` error

### 1.2.2.5: Create Validation Error Class
- [ ] Create `lib/jido_code_core/errors/validation.ex`
- [ ] Define `InvalidParameters` error
- [ ] Define `SchemaValidationFailed` error
- [ ] Define `InvalidSessionId` error

### 1.2.2.6: Create Agent Error Class
- [ ] Create `lib/jido_code_core/errors/agent.ex`
- [ ] Define `AgentNotRunning` error
- [ ] Define `AgentStartupFailed` error
- [ ] Define `AgentTimeout` error

---

## Phase 1.2 Success Criteria

1. **Audit**: All error patterns documented
2. **Splode Setup**: Error classes created and compiling
3. **Integration**: Errors integrate with existing code
4. **Tests**: All error handling tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/errors.ex` | ~100 (new) | Create error module |
| `lib/jido_code_core/errors/*.ex` | ~50 each | Create error classes |

## Rollback Plan

```bash
rm -rf lib/jido_code_core/errors/
```

Proceed to [Section 1.3: Base Types](./03-base-types.md)
