# Phase 8.2: Deprecation Cleanup

Remove all deprecated code after migration is complete.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Deprecation Removal                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Remove Once Agent Mode is Default:                              │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │  ❌ Session.State GenServer (1969 lines)                   │  │
│   │  ❌ Tools.Registry (custom)                                │  │
│   │  ❌ Tools.Executor legacy path                             │  │
│   │  ❌ PubSub event broadcasting                              │  │
│   │  ❌ Compatibility shims                                    │  │
│   │  ❌ Deprecated config options                              │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│   Keep:                                                           │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │  ✅ Jido.Agent + AgentServer                              │  │
│   │  ✅ Skills and Actions                                    │  │
│   │  ✅ StateOps and Directives                               │  │
│   │  ✅ Jido.Signal system                                    │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Action |
|------|--------|
| `lib/jido_code_core/session/state.ex` | Remove after deprecation |
| `lib/jido_code_core/tools/registry.ex` | Remove after deprecation |
| `lib/jido_code_core/tools/executor.ex` | Remove legacy path |
| `lib/jido_code_core/pubsub_helpers.ex` | Simplify after bridge removed |

---

## 8.2.1: Remove Legacy Session.State

Remove the GenServer-based session state.

### 8.2.1.1: Verify Agent Mode is Default
- [ ] Check config for `agent_mode: true`
- [ ] Verify all tests pass in agent mode
- [ ] Confirm no production use of legacy mode

### 8.2.1.2: Remove Session.State GenServer
- [ ] Delete `lib/jido_code_core/session/state.ex`
- [ ] Remove from supervision tree
- [ ] Update imports

### 8.2.1.3: Remove ProcessRegistry
- [ ] Delete `lib/jido_code_core/session/process_registry.ex`
- [ ] Update all lookups to AgentServer
- [ ] Update tests

---

## 8.2.2: Remove Legacy Tool Registry

Remove custom tool registry.

### 8.2.2.1: Verify ToolSkill is Default
- [ ] Check all tools are actions
- [ ] Verify ToolSkill is mounted
- [ ] Confirm tool discovery works

### 8.2.2.2: Remove Tools.Registry
- [ ] Delete `lib/jido_code_core/tools/registry.ex`
- [ ] Update all references
- [ ] Update tests

### 8.2.2.3: Remove Tool Definitions
- [ ] Delete `lib/jido_code_core/tools/definitions/` directory
- [ ] All tools now in actions/
- [ ] Update imports

---

## 8.2.3: Remove Legacy Executor Paths

Clean up executor code.

### 8.2.3.1: Remove Legacy Execution Path
- [ ] Open `lib/jido_code_core/tools/executor.ex`
- [ ] Remove legacy execute function
- [ ] Remove feature flag support
- [ ] Keep only AgentExecutor

### 8.2.3.2: Remove AgentExecutor Module
- [ ] Move AgentExecutor logic into Executor
- [ ] Delete `lib/jido_code_core/tools/agent_executor.ex`
- [ ] Update all imports

---

## 8.2.4: Simplify PubSub Layer

Clean up after PubSub bridge.

### 8.2.4.1: Remove PubSub Bridge
- [ ] Delete `lib/jido_code_core/signals/pubsub_bridge.ex`
- [ ] Remove from supervision tree
- [ ] All events now use Jido.Signal

### 8.2.4.2: Simplify PubSubHelpers
- [ ] Open `lib/jido_code_core/pubsub_helpers.ex`
- [ ] Remove legacy broadcast functions
- [ ] Keep only signal-related helpers if needed

### 8.2.4.3: Remove PubSubAdapter
- [ ] Delete `lib/jido_code_core/signals/pubsub_adapter.ex`
- [ ] All code uses Jido.Signal directly

---

## 8.2.5: Remove Compatibility Shims

Clean up compatibility code.

### 8.2.5.1: Remove Feature Flags
- [ ] Remove `:agent_mode` config
- [ ] Remove mode detection code
- [ ] Remove routing shims

### 8.2.5.2: Remove Migration Code
- [ ] Delete `lib/jido_code_core/migration/` directory
- [ ] Remove state migrator
- [ ] Remove migration hooks

### 8.2.5.3: Remove Converters
- [ ] Delete `lib/jido_code_core/agent/converters.ex`
- [ ] No longer needed after migration

---

## Phase 8.2 Success Criteria

1. **Removal**: All deprecated code removed
2. **Tests**: All tests still pass after removal
3. **Build**: Project compiles cleanly
4. **Lint**: No warnings or errors
5. **Documentation**: Updated to reflect removals

## Files Removed

| File | Lines | Reason |
|------|-------|--------|
| `lib/jido_code_core/session/state.ex` | ~2000 | Replaced by Agent |
| `lib/jido_code_core/session/process_registry.ex` | ~100 | Replaced by AgentServer |
| `lib/jido_code_core/tools/registry.ex` | ~200 | Replaced by Actions |
| `lib/jido_code_core/tools/definitions/*.ex` | ~500 | Replaced by Actions |
| `lib/jido_code_core/tools/agent_executor.ex` | ~200 | Merged into Executor |
| `lib/jido_code_core/signals/pubsub_bridge.ex` | ~150 | No longer needed |
| `lib/jido_code_core/signals/pubsub_adapter.ex` | ~100 | No longer needed |
| `lib/jido_code_core/migration/*` | ~200 | Migration complete |
| `lib/jido_code_core/agent/converters.ex` | ~200 | Migration complete |

## Rollback Plan

Git revert from backup before cleanup.

Proceed to [Section 8.3: Documentation](./03-documentation.md)
