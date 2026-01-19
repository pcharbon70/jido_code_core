# Phase 2: State Management - Overview

## Description

Migrate from the current GenServer-based state management to Jido.Agent with StateOps. This phase replaces the monolithic Session.State GenServer (1969 lines) with a functional agent pattern using StateOps for state mutations and Directives for side effects.

## Goal

Transform state management from imperative to declarative:
1. Replace GenServer state with Jido.Agent pure functions
2. Migrate state mutations to StateOp patterns
3. Replace PubSub broadcasts with Directive.Emit

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   Current vs Target Architecture                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Current (GenServer)                 Target (Jido.Agent)                  │
│  ────────────────────                ────────────────────                 │
│  ┌─────────────────────┐             ┌─────────────────────┐             │
│  │ Session.State      │             │ CodeSessionAgent    │             │
│  │ GenServer           │      ────>  │ + AgentServer       │             │
│  │ 1969 lines          │             │ pure functional     │             │
│  └─────────────────────┘             └─────────────────────┘             │
│           │                                      │                        │
│           ▼                                      ▼                        │
│  ┌─────────────────────┐             ┌─────────────────────┐             │
│  │ Direct state        │      ────>  │ StateOps            │             │
│  │ mutations           │             │ (SetState, etc.)    │             │
│  └─────────────────────┘             └─────────────────────┘             │
│           │                                      │                        │
│           ▼                                      ▼                        │
│  ┌─────────────────────┐             ┌─────────────────────┐             │
│  │ Phoenix.PubSub      │      ────>  │ Directive.Emit      │             │
│  │ broadcast           │             │ (Signal.Emit)       │             │
│  └─────────────────────┘             └─────────────────────┘             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| Component | Purpose |
|-----------|---------|
| CodeSessionAgent | New Jido.Agent for session management |
| SessionStateOps | Helper functions for StateOp creation |
| DirectiveBuilders | Helper functions for Directive.Emit |
| StateOpsMap | Documentation of current → StateOp patterns |

## Phases in This Stage

| Section | Document | Description |
|---------|----------|-------------|
| 2.1 | [01-agent-structure.md](./01-agent-structure.md) | Create Jido.Agent structure |
| 2.2 | [02-stateops-migration.md](./02-stateops-migration.md) | Map state changes to StateOps |
| 2.3 | [03-directive-migration.md](./03-directive-migration.md) | Replace PubSub with Directives |

## Success Criteria

1. **Agent**: CodeSessionAgent compiles and runs correctly
2. **StateOps**: State mutations use StateOp patterns
3. **Directives**: Side effects use Directive.Emit
4. **Tests**: All tests pass
5. **Performance**: No performance regression

## Dependencies on Previous Phases

- **Phase 1**: Dependencies, error handling, and base types must be in place

## Key References

- [Jido.Agent Documentation](../../../jido/lib/jido/agent.ex)
- [StateOps Module](../../../jido/lib/jido/agent/state_ops.ex)
- [Directives Documentation](../../../jido/guides/directives.md)

Proceed to [Section 2.1: Agent Structure](./01-agent-structure.md)
