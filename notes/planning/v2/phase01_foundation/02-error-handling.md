# Phase 1.2: Error Handling

Migrate to Splode-based error handling while maintaining backward compatibility.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Error Handling Flow                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────┐     ┌─────────────┐     ┌────────────┐  │
│   │ Legacy Code │────>│ Error       │────>│ Splode     │  │
│   │             │     │ Converters  │     │ Errors     │  │
│   └─────────────┘     └─────────────┘     └────────────┘  │
│         │                                       │          │
│         v                                       v          │
│   ┌────────────────────────────────────────────────────┐  │
│   │              Unified Error Interface               │  │
│   │  {:ok, result} | {:error, error_struct}           │  │
│   └────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/error.ex` | Existing error module |
| `lib/jido_code_core/errors/` | New error module directory |

---

## 1.2.1: Audit Current Error Patterns

Document all existing error patterns before migration.

### 1.2.1.1: Review Existing Error Module
- [ ] Read `/home/ducky/code/agentjido/jido_code_core/lib/jido_code_core/error.ex`
- [ ] Document all custom error types defined
- [ ] Identify all error return patterns

### 1.2.1.2: Scan for Tuple-Based Errors
- [ ] Search for `{:error, reason}` patterns in codebase
- [ ] Document all unique error reason atoms
- [ ] Identify error tuple locations in:
  - `lib/jido_code_core/tools/executor.ex`
  - `lib/jido_code_core/session/state.ex`
  - `lib/jido_code_core/memory/`

### 1.2.1.3: Create Error Documentation
- [ ] Document all error types in `notes/research/error_patterns.md`
- [ ] Map legacy errors to Splode equivalents
- [ ] Create error migration matrix

---

## 1.2.2: Introduce Splode Error Wrappers

Add Splode-based error handling with backward compatibility.

### 1.2.2.1: Create Error Module Structure
- [ ] Create `lib/jido_code_core/errors/` directory
- [ ] Create `lib/jido_code_core/errors.ex` with Splode setup:

```elixir
defmodule JidoCodeCore.Errors do
  use Splode, error_classes: [
    session: JidoCodeCore.Errors.Session,
    tools: JidoCodeCore.Errors.Tools,
    memory: JidoCodeCore.Errors.Memory,
    validation: JidoCodeCore.Errors.Validation
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

### 1.2.2.6: Add Error Conversion Helpers
- [ ] Add `from_legacy/1` function to convert tuple errors
- [ ] Add `to_legacy/1` function for backward compatibility
- [ ] Maintain existing error return patterns

---

## Phase 1.2 Success Criteria

1. **Audit**: All error patterns documented
2. **Splode Setup**: Error classes created and compiling
3. **Conversion**: Legacy errors can convert to Splode
4. **Backward Compatibility**: Existing code still works
5. **Tests**: All existing error handling tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/error.ex` | ~50 | Add Splode wrappers |
| `lib/jido_code_core/errors.ex` | ~100 (new) | Create error classes |
| `lib/jido_code_core/errors/*.ex` | ~50 each | Individual error classes |

## Rollback Plan

```bash
rm -rf lib/jido_code_core/errors/
rm -f lib/jido_code_core/errors.ex
git checkout lib/jido_code_core/error.ex
```

Proceed to [Section 1.3: Base Types](./03-base-types.md)
