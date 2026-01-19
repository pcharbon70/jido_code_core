# Phase 5: Tool Integration - Overview

## Description

Migrate the custom tool registry and executor to use Jido.Actions and Agent patterns. This phase converts existing tool definitions into actions and integrates them with the new agent architecture.

## Goal

Transform the tool system:
1. Migrate tool registry to Jido.Actions
2. Refactor executor to use Agent cmd/2
3. Convert tool definitions to actions

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Tool Integration Architecture                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Current Pattern                    Target Pattern                       │
│   ────────────────────                ────────────────                   │
│   ┌─────────────────┐                 ┌─────────────────┐                │
│   │ Tools.Registry   │      ──────>    │ Jido.Actions    │                │
│   │ (custom)         │                 │ (standard)      │                │
│   └─────────────────┘                 └─────────────────┘                │
│           │                                      │                       │
│           ▼                                      ▼                       │
│   ┌─────────────────┐                 ┌─────────────────┐                │
│   │ Tools.Executor  │      ──────>    │ Agent cmd/2     │                │
│   │ (custom flow)    │                 │ + Directives     │                │
│   └─────────────────┘                 └─────────────────┘                │
│           │                                      │                       │
│           ▼                                      ▼                       │
│   ┌─────────────────┐                 ┌─────────────────┐                │
│   │ Handler Modules │      ──────>    │ ToolSkill       │                │
│   │ (ad hoc)        │                 │ (composable)    │                │
│   └─────────────────┘                 └─────────────────┘                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| Component | Purpose |
|-----------|---------|
| Tool Actions | Actions wrapping tool handlers |
| Agent Executor | New executor using Agent cmd/2 |
| ToolSkill | Aggregate skill for all tools |

## Phases in This Stage

| Section | Document | Description |
|---------|----------|-------------|
| 5.1 | [01-tool-registry-migration.md](./01-tool-registry-migration.md) | Map tools to actions |
| 5.2 | [02-executor-refactor.md](./02-executor-refactor.md) | Refactor executor |
| 5.3 | [03-tool-actions.md](./03-tool-actions.md) | Convert tool definitions |

## Success Criteria

1. **Tool Actions**: All tools available as actions
2. **Agent Executor**: Executor using Agent patterns
3. **ToolSkill**: Aggregate skill functional
4. **Tests**: All tool tests pass

## Dependencies on Previous Phases

- **Phase 1**: Base types and error handling
- **Phase 2**: Agent structure and StateOps
- **Phase 4**: Skills and Actions

## Key References

- [Tools.Executor](../../lib/jido_code_core/tools/executor.ex)
- [Tools.Registry](../../lib/jido_code_core/tools/registry.ex)
- [Tool Definitions](../../lib/jido_code_core/tools/definitions/)

Proceed to [Section 5.1: Tool Registry Migration](./01-tool-registry-migration.md)
