# Phase 6: Session Migration - Overview

## Description

Migrate from the Session.State GenServer to Jido.AgentServer while maintaining backward compatibility for existing APIs.

## Goal

Replace GenServer-based session with Agent pattern:
1. Adopt AgentServer for session management
2. Migrate existing session state data
3. Maintain API compatibility during transition

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       Session Migration Architecture                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Current (GenServer)                 Target (AgentServer)                 │
│   ─────────────────────                 ─────────────────                 │
│                                                                          │
│   ┌─────────────────┐                  ┌─────────────────┐               │
│   │ Session.State    │                  │ CodeSessionAgent │               │
│   │ GenServer        │       ───────>   │ + AgentServer    │               │
│   │ 1969 lines       │                  │ pure functional  │               │
│   └─────────────────┘                  └────────┬────────┘               │
│                                                 │                        │
│                                                 ▼                        │
│   ┌─────────────────┐                  ┌─────────────────┐               │
│   │ Session.Manager │                  │ SessionAPI      │               │
│   │ (client API)     │       ───────>   │ (compat layer)  │               │
│   └─────────────────┘                  └─────────────────┘               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| Component | Purpose |
|-----------|---------|
| CodeSessionAgentServer | AgentServer wrapper for CodeSessionAgent |
| State Migrator | Convert Session.State to Agent state |
| Session API Adapter | Maintain backward compatibility |
| Feature Flag | Enable/disable Agent mode |

## Phases in This Stage

| Section | Document | Description |
|---------|----------|-------------|
| 6.1 | [01-agentserver-adoption.md](./01-agentserver-adoption.md) | Adopt AgentServer |
| 6.2 | [02-state-data-migration.md](./02-state-data-migration.md) | Migrate state data |
| 6.3 | [03-api-compatibility.md](./03-api-compatibility.md) | API compatibility layer |

## Success Criteria

1. **AgentServer**: CodeSessionAgentServer running
2. **Migration**: State data migrates correctly
3. **Compatibility**: Existing APIs still work
4. **Feature Flag**: Can toggle between modes
5. **Tests**: All session tests pass

## Dependencies on Previous Phases

- **Phase 1**: Base types and converters
- **Phase 2**: Agent structure and StateOps
- **Phase 3**: Signal system
- **Phase 4**: Skills
- **Phase 5**: Tool integration

## Key References

- [Jido.AgentServer Documentation](../../../jido/lib/jido/agent_server.ex)
- [Session.State](../../lib/jido_code_core/session/state.ex)
- [Session.Manager](../../lib/jido_code_core/session/manager.ex)

Proceed to [Section 6.1: AgentServer Adoption](./01-agentserver-adoption.md)
