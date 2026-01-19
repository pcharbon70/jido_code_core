# Phase 3: Signal System - Overview

## Description

Complete the signal system by defining all signal types and establishing signal routing patterns for the agent.

## Goal

Establish a complete signal-based event system:
1. Define all JidoCodeCore signal types
2. Set up signal routing for CodeSessionAgent
3. Integrate with Jido.Signal dispatch

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       Signal System Architecture                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────┐     Emit      ┌──────────────┐     Route     ┌───┐│
│  │ Agent.cmd/2     │──────────────>│ Signal Router │──────────────>│Act││
│  │ + Directives    │   Directive.  │              │               │ion││
│  │                 │   Emit        └──────────────┘               └───┘│
│  └─────────────────┘                                              │    │
│           │                                                       │    │
│           ▼                                                       ▼    │
│  ┌─────────────────┐     Dispatch    ┌──────────────┐                  │
│  │ Jido.Signal     │<────────────────│ Subscribers  │                  │
│  │ Dispatch        │                 │              │                  │
│  └─────────────────┘                  └──────────────┘                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| Component | Purpose |
|-----------|---------|
| Signals Module | All signal type definitions |
| Signal Router | Route signals to actions |
| Jido.Signal.Dispatch | Signal dispatch system |

## Phases in This Stage

| Section | Document | Description |
|---------|----------|-------------|
| 3.1 | [01-signal-types.md](./01-signal-types.md) | Define all signal types |
| 3.2 | [02-signal-routing.md](./02-signal-routing.md) | Set up signal routing |

## Success Criteria

1. **Signals**: All signal types defined and validated
2. **Routing**: Signal routes working correctly
3. **Dispatch**: Signal dispatch integrated
4. **Tests**: All signal system tests pass

## Dependencies on Previous Phases

- **Phase 1**: Base types and error handling
- **Phase 2**: CodeSessionAgent and Directives

## Key References

- [Jido.Signal Documentation](../../../jido/guides/signals.md)
- [Jido.Dispatch](../../../jido/lib/jido/dispatch.ex)

Proceed to [Section 3.1: Signal Types](./01-signal-types.md)
