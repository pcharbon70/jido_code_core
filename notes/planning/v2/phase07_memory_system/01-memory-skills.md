# Phase 7.1: Memory Skills

Package memory operations as composable Skills.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Memory Skill Structure                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                   MemorySkill                             │  │
│   │  use Jido.Skill                                         │  │
│   │    name: "memory"                                        │  │
│   │    state_key: :memory                                    │  │
│   │    actions: [Remember, Recall, Forget]                   │  │
│   │    schema: %{working_context, pending_memories, ...}      │  │
│   └─────────────────────────────────────────────────────────┘  │
│                            │                                    │
│                            ├──> Remember Action                │
│                            ├──> Recall Action                  │
│                            └──> Forget Action                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/skills/memory.ex` | Memory skill definition |
| `lib/jido_code_core/memory/actions/*.ex` | Existing actions (update if needed) |

---

## 7.1.1: Create Base MemorySkill

Define the core MemorySkill module.

### 7.1.1.1: Define MemorySkill Structure
- [ ] Update `lib/jido_code_core/skills/memory.ex`
- [ ] Ensure proper schema definition

```elixir
defmodule JidoCodeCore.Skills.Memory do
  use Jido.Skill,
    name: "memory",
    state_key: :memory,
    description: "Memory operations for storing and recalling information",
    category: "memory",
    actions: [
      JidoCodeCore.Memory.Actions.Remember,
      JidoCodeCore.Memory.Actions.Recall,
      JidoCodeCore.Memory.Actions.Forget
    ],
    schema: Zoi.object(%{
      pending_memories: Zoi.list(Zoi.any())
        |> Zoi.default([])
        |> Zoi.description("Staging area for memories awaiting promotion"),
      access_log: Zoi.map(Zoi.any(), Zoi.any())
        |> Zoi.default(%{})
        |> Zoi.description("Usage tracking for importance scoring"),
      working_context: Zoi.map(Zoi.any(), Zoi.any())
        |> Zoi.default(%{})
        |> Zoi.description("Semantic scratchpad for session context")
    }),
    signal_patterns: ["jido_code.memory.*"]
end
```

### 7.1.1.2: Add mount/2 Callback
- [ ] Initialize memory tracking state
- [ ] Set up access log
- [ ] Initialize working context

```elixir
@impl Jido.Skill
def mount(_agent, config) do
  # Initialize memory tracking from config
  max_pending = Keyword.get(config, :max_pending_memories, 500)
  max_log_entries = Keyword.get(config, :max_access_log_entries, 1000)

  {:ok, %{
    pending_memories: [],
    access_log: %{},
    working_context: %{},
    max_pending: max_pending,
    max_log_entries: max_log_entries
  }}
end
```

### 7.1.1.3: Add router/1 Callback
- [ ] Map memory signals to actions
- [ ] Add wildcard support
- [ ] Return routing table

---

## 7.1.2: Add Memory State Management

Manage memory-specific state operations.

### 7.1.2.1: Add Working Context Helpers
- [ ] `update_context/3` - Update context item
- [ ] `get_context/2` - Get context item
- [ ] `clear_context/1` - Clear all context

### 7.1.2.2: Add Pending Memory Helpers
- [ ] `add_pending_memory/2` - Stage memory
- [ ] `get_pending_memories/1` - Get ready memories
- [ ] `clear_promoted/2` - Remove promoted

### 7.1.2.3: Add Access Log Helpers
- [ ] `record_access/3` - Log access event
- [ ] `get_access_stats/2` - Get statistics
- [ ] `prune_log/2` - Limit log size

---

## 7.1.3: Create MemorySkill Tests

Test memory skill functionality.

### 7.1.3.1: Test Skill Mounting
- [ ] Test mount/2 initializes state
- [ ] Test config options
- [ ] Verify defaults

### 7.1.3.2: Test Working Context
- [ ] Test context updates
- [ ] Test context retrieval
- [ ] Test context clearing

### 7.1.3.3: Test Pending Memories
- [ ] Test adding pending memories
- [ ] Test getting ready memories
- [ ] Test clearing promoted

### 7.1.3.4: Test Access Log
- [ ] Test access recording
- [ ] Test statistics retrieval
- [ ] Test log pruning

---

## Phase 7.1 Success Criteria

1. **MemorySkill**: Defined and working
2. **Mount**: Callback initializes state correctly
3. **Router**: Signals route to actions
4. **Helpers**: State management functions working
5. **Tests**: All MemorySkill tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/skills/memory.ex` | +100 | Update skill |
| `test/jido_code_core/skills/memory_skill_test.exs` | ~200 (new) | Tests |

## Rollback Plan

```bash
git checkout lib/jido_code_core/skills/memory.ex
rm -f test/jido_code_core/skills/memory_skill_test.exs
```

Proceed to [Section 7.2: Promotion Engine](./02-promotion-engine.md)
