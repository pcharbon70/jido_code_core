# Phase 1: Foundation - Overview

## Description

Establish the foundational infrastructure for JidoCodeCore based on Jido 2.0 patterns. This phase focuses on dependency management, error handling implementation, and base type definitions that will be used throughout the application.

## Goal

Create a solid foundation by:
1. Ensuring all Jido 2.0 dependencies are properly configured
2. Implementing Splode-based error handling
3. Defining base types and schemas for the architecture

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Phase 1 Foundation Layer                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────┐  │
│  │ Dependencies    │────>│ Error Handling  │────>│ Base Types  │  │
│  │ Jido 2.0        │     │ Splode Errors   │     │ Zoi Schemas │  │
│  │ Jido.AI 2.0     │     │                 │     │             │  │
│  │ Zoi, Splode     │     │                 │     │             │  │
│  └─────────────────┘     └─────────────────┘     └─────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| Component | Purpose |
|-----------|---------|
| mix.exs | Configure Jido 2.0 dependencies |
| Errors module | Splode-based error handling |
| Agent.Schemas | Zoi schemas for agent state |

## Phases in This Stage

| Section | Document | Description |
|---------|----------|-------------|
| 1.1 | [01-dependencies-build.md](./01-dependencies-build.md) | Update and verify all dependencies |
| 1.2 | [02-error-handling.md](./02-error-handling.md) | Migrate to Splode error patterns |
| 1.3 | [03-base-types.md](./03-base-types.md) | Define base types and schemas |

## Success Criteria

1. **Dependencies**: All Jido 2.0 dependencies compile without conflicts
2. **Error Handling**: Splode error helpers available and tested
3. **Base Types**: Schemas defined with validation
4. **Test Coverage**: All tests pass

## Dependencies on Previous Phases

None - this is the foundational phase.

## Key References

- [Jido 2.0 Migration Guide](../../../jido/guides/migration.md)
- [Jido Error Handling](../../../jido/guides/errors.md)
- [Zoi Schema Documentation](https://hexdocs.pm/zoi)

Proceed to [Section 1.1: Dependencies & Build](./01-dependencies-build.md)
