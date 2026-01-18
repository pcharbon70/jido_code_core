# Phase 8.1: Test Coverage

Ensure comprehensive test coverage for all migrated code.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Test Pyramid                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                        ┌─────────┐                             │
│                       ╱         ╲                            │
│                      ╱   E2E     ╲                           │
│                     ╱_____________╲                          │
│                    ╱              ╲                         │
│                   ╱    Integration  ╲                        │
│                  ╱____________________╲                       │
│                 ╱                      ╲                      │
│                ╱       Unit Tests        ╲                     │
│               ╱______________________________╲                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| Directory | Purpose |
|-----------|---------|
| `test/jido_code_core/agent/` | Agent tests |
| `test/jido_code_core/skills/` | Skill tests |
| `test/jido_code_core/actions/` | Action tests |
| `test/jido_code_core/signals/` | Signal tests |
| `test/jido_code_core/migration/` | Migration tests |

---

## 8.1.1: Add Agent Tests

Test the core Agent functionality.

### 8.1.1.1: Create CodeSessionAgent Tests
- [ ] Test agent creation
- [ ] Test agent initialization
- [ ] Test state updates
- [ ] Test cmd/2 execution

### 8.1.1.2: Create AgentServer Tests
- [ ] Test server startup
- [ ] Test signal routing
- [ ] Test child processes
- [ ] Test graceful shutdown

### 8.1.1.3: Create StateOps Tests
- [ ] Test all StateOp types
- [ ] Test apply_state_ops/2
- [ ] Test state mutations

---

## 8.1.2: Add Skill Tests

Test all skill modules.

### 8.1.2.1: Create FileSystemSkill Tests
- [ ] Test skill mounting
- [ ] Test state isolation
- [ ] Test action routing
- [ ] Test file tracking

### 8.1.2.2: Create MemorySkill Tests
- [ ] Test skill mounting
- [ ] Test working context
- [ ] Test pending memories
- [ ] Test access log

### 8.1.2.3: Create ToolSkill Tests
- [ ] Test skill mounting
- [ ] Test tool discovery
- [ ] Test tool execution
- [ ] Test LLM format

### 8.1.2.4: Create PromotionSkill Tests
- [ ] Test skill mounting
- [ ] Test promotion triggers
- [ ] Test schedule execution
- [ ] Test TripleStore integration

---

## 8.1.3: Add Action Tests

Test all action modules.

### 8.1.3.1: Create Tool Action Tests
- [ ] Test all tool actions
- [ ] Test parameter validation
- [ ] Test execution
- [ ] Test error handling

### 8.1.3.2: Create Memory Action Tests
- [ ] Test Remember action
- [ ] Test Recall action
- [ ] Test Forget action
- [ ] Test schema validation

---

## 8.1.4: Add Migration Tests

Verify migration from old to new patterns.

### 8.1.4.1: Create State Migration Tests
- [ ] Test Session → Agent conversion
- [ ] Test Agent → Session conversion
- [ ] Test round-trip conversion
- [ ] Test data preservation

### 8.1.4.2: Create API Compatibility Tests
- [ ] Test both modes return same results
- [ ] Test feature flag toggling
- [ ] Test mode switching

---

## 8.1.5: Add Integration Tests

Test end-to-end functionality.

### 8.1.5.1: Create Session Lifecycle Tests
- [ ] Test session creation
- [ ] Test session updates
- [ ] Test session termination
- [ ] Test cleanup

### 8.1.5.2: Create Tool Execution Tests
- [ ] Test tool calling via signals
- [ ] Test tool result handling
- [ ] Test error scenarios
- [ ] Test concurrent execution

### 8.1.5.3: Create Memory Promotion Tests
- [ ] Test automatic promotion
- [ ] Test importance scoring
- [ ] Test TripleStore persistence
- [ ] Test access tracking

---

## 8.1.6: Verify Coverage

Ensure test coverage meets standards.

### 8.1.6.1: Run Coverage Analysis
- [ ] Run `mix test.coverage`
- [ ] Check overall coverage > 80%
- [ ] Identify uncovered modules

### 8.1.6.2: Add Missing Tests
- [ ] Add tests for uncovered lines
- [ ] Add edge case tests
- [ ] Add error path tests

### 8.1.6.3: Verify Coverage
- [ ] Re-run coverage analysis
- [ ] Confirm all modules > 80%
- [ ] Document any exclusions

---

## Phase 8.1 Success Criteria

1. **Agent Tests**: All agent tests passing
2. **Skill Tests**: All skill tests passing
3. **Action Tests**: All action tests passing
4. **Migration Tests**: Migration verified
5. **Coverage**: Overall coverage > 80%

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `test/jido_code_core/agent/*_test.exs` | ~800 (new) | Agent tests |
| `test/jido_code_core/skills/*_test.exs` | ~600 (new) | Skill tests |
| `test/jido_code_core/actions/*_test.exs` | ~1000 (new) | Action tests |
| `test/jido_code_core/migration/*_test.exs` | ~400 (new) | Migration tests |
| `test/jido_code_core/integration/*_test.exs` | ~600 (new) | Integration tests |

## Rollback Plan

N/A - Tests only, no production code changes.

Proceed to [Section 8.2: Deprecation Cleanup](./02-deprecation-cleanup.md)
