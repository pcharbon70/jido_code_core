# Phase 7: Memory System - Overview

## Description

Package memory operations as composable Skills and migrate the promotion engine to use StateOps.

## Goal

Transform memory system:
1. Package memory operations as composable Skills
2. Migrate promotion engine to use StateOps
3. Keep TripleStore as backend with action-based access

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       Memory System Architecture                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                     CodeSessionAgent                             │  │
│   │  skills: [                                                        │  │
│   │    ...,                                                           │  │
│   │    MemorySkill,      # Core memory operations                    │  │
│   │    PromotionSkill    # Automatic memory promotion                 │  │
│   │  ]                                                                │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                            │                                           │
│                            ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                    Memory Skill State                            │  │
│   │  working_context: Semantic scratchpad                           │  │
│   │  pending_memories: Staging area                                 │  │
│   │  access_log: Usage tracking                                      │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                            │                                           │
│                            ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                   TripleStore Backend                           │  │
│   │  (Long-term memory storage)                                      │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| Component | Purpose |
|-----------|---------|
| MemorySkill | Core memory operations |
| PromotionSkill | Automatic promotion engine |
| TripleStore Actions | Backend access actions |

## Phases in This Stage

| Section | Document | Description |
|---------|----------|-------------|
| 7.1 | [01-memory-skills.md](./01-memory-skills.md) | Package memory operations |
| 7.2 | [02-promotion-engine.md](./02-promotion-engine.md) | Migrate promotion |
| 7.3 | [03-triplestore-integration.md](./03-triplestore-integration.md) | Backend access |

## Success Criteria

1. **MemorySkill**: Core memory operations as skill
2. **PromotionSkill**: Promotion engine working
3. **TripleStore**: Backend actions functional
4. **Integration**: All memory tests pass
5. **StateIsolation**: Memory state properly isolated

## Dependencies on Previous Phases

- **Phase 1**: Base types and converters
- **Phase 2**: Agent structure and StateOps
- **Phase 4**: Skills and Actions

## Key References

- [Memory.Actions](../../lib/jido_code_core/memory/actions.ex)
- [Promotion.Engine](../../lib/jido_code_core/memory/promotion/engine.ex)

Proceed to [Section 7.1: Memory Skills](./01-memory-skills.md)
