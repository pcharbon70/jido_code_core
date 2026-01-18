# Phase 6.1: AgentServer Adoption

Create CodeSessionAgentServer to replace Session.State GenServer.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    AgentServer Structure                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              CodeSessionAgentServer                       │  │
│   │  use Jido.AgentServer                                    │  │
│   │    agent: CodeSessionAgent                               │  │
│   │    signal_dispatcher: Jido.Signal.Dispatch               │  │
│   └─────────────────────────────────────────────────────────┘  │
│                            │                                    │
│                            ├──> PubSubBridge (child)            │
│                            ├──> Child Agents (optional)         │
│                            └──> Other processes                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/agent/server.ex` | AgentServer definition |
| `lib/jido_code_core/session/supervisor.ex` | Update supervision tree |

---

## 6.1.1: Create CodeSessionAgentServer

Create AgentServer wrapper for CodeSessionAgent.

### 6.1.1.1: Create AgentServer Module
- [ ] Create `lib/jido_code_core/agent/server.ex`
- [ ] Set up AgentServer configuration

```elixir
defmodule JidoCodeCore.Agent.Server do
  @moduledoc """
  AgentServer wrapper for CodeSessionAgent.

  Replaces the Session.State GenServer with Jido.AgentServer pattern.
  """

  use Jido.AgentServer,
    agent: JidoCodeCore.Agent.CodeSession,
    signal_dispatcher: Jido.Signal.Dispatch,
    name: __MODULE__

  # Optional: Add child processes
  def children(_agent, _opts) do
    [
      # PubSub bridge for backward compatibility
      {JidoCodeCore.Signals.PubSubBridge, []}
    ]
  end
end
```

### 6.1.1.2: Add Server Lifecycle Hooks
- [ ] Implement `on_init/2` for session setup
- [ ] Implement `on_terminate/2` for cleanup
- [ ] Add telemetry hooks

### 6.1.1.3: Create Server Tests
- [ ] Test AgentServer startup
- [ ] Test signal routing
- [ ] Test child processes

---

## 6.1.2: Update Session Supervisor

Replace Session.State with AgentServer.

### 6.1.2.1: Update Supervisor Children
- [ ] Open `lib/jido_code_core/session/supervisor.ex`
- [ ] Replace Session.State child spec

```elixir
# Before
{JidoCodeCore.Session.State, [session: session]}

# After (with feature flag)
if Application.get_env(:jido_code_core, :agent_mode, false) do
  {JidoCodeCore.Agent.Server, [agent_opts: [initial_state: to_agent_state(session)]]}
else
  {JidoCodeCore.Session.State, [session: session]}
end
```

### 6.1.2.2: Add ProcessRegistry Support
- [ ] Ensure AgentServer registers with ProcessRegistry
- [ ] Support existing lookup patterns
- [ ] Maintain compatibility

---

## 6.1.3: Add Server Configuration

Configure AgentServer behavior.

### 6.1.3.1: Add Configuration Options
- [ ] Add `:agent_mode` config flag
- [ ] Add `:server_timeout` config
- [ ] Add `:max_iterations` for ReAct

### 6.1.3.2: Add Runtime Configuration
- [ ] Support runtime mode switching
- [ ] Add configuration validation
- [ ] Document configuration options

---

## Phase 6.1 Success Criteria

1. **AgentServer**: CodeSessionAgentServer compiles
2. **Supervisor**: Updated with AgentServer child
3. **Registry**: ProcessRegistry integration working
4. **Configuration**: Feature flag functional
5. **Tests**: Server tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/agent/server.ex` | ~150 (new) | Server definition |
| `lib/jido_code_core/session/supervisor.ex` | ~40 | Update children |
| `config/config.exs` | ~20 | Add config |
| `test/jido_code_core/agent/server_test.exs` | ~150 (new) | Tests |

## Rollback Plan

```bash
rm -f lib/jido_code_core/agent/server.ex
git checkout lib/jido_code_core/session/supervisor.ex
git checkout config/config.exs
rm -f test/jido_code_core/agent/server_test.exs
```

Proceed to [Section 6.2: State Data Migration](./02-state-data-migration.md)
