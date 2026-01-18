# Phase 1: Foundation - Overview

## Description

Establish the foundational infrastructure for migrating JidoCodeCore to Jido 2.0 patterns. This phase focuses on dependency management, error handling migration, and base type definitions that will be used throughout the rest of the migration.

## Goal

Create a solid foundation for the migration by:
1. Ensuring all Jido 2.0 dependencies are properly configured
2. Introducing Splode-based error handling with backward compatibility
3. Defining base types and schemas for the new architecture

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Phase 1 Foundation Layer                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────┐  │
│  │ Dependencies    │────>│ Error Handling  │────>│ Base Types  │  │
│  │ Jido 2.0        │     │ Splode Wrappers │     │ Zoi Schemas │  │
│  │ Jido.AI 2.0     │     │ Legacy Support  │     │ Converters  │  │
│  │ Zoi, Splode     │     │                 │     │             │  │
│  └─────────────────┘     └─────────────────┘     └─────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| Component | Purpose |
|-----------|---------|
| mix.exs | Update dependencies to Jido 2.0 compatible versions |
| Error module | Introduce Splode-based error handling with legacy wrappers |
| Agent.Schemas | Define Zoi schemas for session agent state |
| Agent.Converters | Create bidirectional converters between Session and Agent |

## Phases in This Stage

| Section | Document | Description |
|---------|----------|-------------|
| 1.1 | [01-dependencies-build.md](./01-dependencies-build.md) | Update and verify all dependencies |
| 1.2 | [02-error-handling.md](./02-error-handling.md) | Migrate to Splode error patterns |
| 1.3 | [03-base-types.md](./03-base-types.md) | Define base types and converters |

## Success Criteria

1. **Dependencies**: All Jido 2.0 dependencies compile without conflicts
2. **Error Handling**: Splode error helpers available and tested with backward compatibility
3. **Base Types**: Schemas defined with validation, converters working bidirectionally
4. **Test Coverage**: All existing tests still pass after changes

## Dependencies on Previous Phases

None - this is the foundational phase.

## Key References

- [Jido 2.0 Migration Guide](../../../jido/guides/migration.md)
- [Jido Error Handling](../../../jido/guides/errors.md)
- [Zoi Schema Documentation](https://hexdocs.pm/zoi)

Proceed to [Section 1.1: Dependencies & Build](./01-dependencies-build.md)
