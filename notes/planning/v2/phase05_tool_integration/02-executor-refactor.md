# Phase 5.2: Executor Refactor

Refactor Tools.Executor to use Agent cmd/2 pattern.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   Executor Architecture Migration                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Current Executor                   Agent-Based Executor          │
│   ──────────────────────               ────────────────          │
│                                                                  │
│   ┌─────────────────┐                 ┌─────────────────┐        │
│   │ Parse Tool Call │                 │ Parse Tool Call │        │
│   └────────┬────────┘                 └────────┬────────┘        │
│            │                                   │                 │
│            ▼                                   ▼                 │
│   ┌─────────────────┐                 ┌─────────────────┐        │
│   │ Validate Tool   │                 │ Validate Tool   │        │
│   │ (Registry)      │                 │ (Actions)       │        │
│   └────────┬────────┘                 └────────┬────────┘        │
│            │                                   │                 │
│            ▼                                   ▼                 │
│   ┌─────────────────┐                 ┌─────────────────┐        │
│   │ Execute Handler │                 │ Agent.cmd/2      │        │
│   │ (Direct call)   │      ────>      │ + Action        │        │
│   └────────┬────────┘                 └────────┬────────┘        │
│            │                                   │                 │
│            ▼                                   ▼                 │
│   ┌─────────────────┐                 ┌─────────────────┐        │
│   │ PubSub Broadcast│                 │ Directive.Emit   │        │
│   └─────────────────┘                 └─────────────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/tools/agent_executor.ex` | New Agent-based executor |
| `lib/jido_code_core/tools/executor.ex` | Legacy executor (compatibility) |

---

## 5.2.1: Create Agent-Based Executor

New executor using Agent cmd/2 pattern.

### 5.2.1.1: Create AgentExecutor Module
- [ ] Create `lib/jido_code_core/tools/agent_executor.ex`
- [ ] Implement execute/2 function

```elixir
defmodule JidoCodeCore.Tools.AgentExecutor do
  @moduledoc """
  Agent-based tool executor using Jido.Agent cmd/2.
  """

  alias JidoCodeCore.Agent.CodeSession
  alias JidoCodeCore.Signals

  def execute(tool_call, opts \\ []) do
    context = Keyword.get(opts, :context, %{})
    agent = Keyword.get(opts, :agent)

    # Create signal for tool execution
    signal = Signals.ToolCall.new!(%{
      tool_name: tool_call.name,
      params: tool_call.arguments,
      call_id: tool_call.id,
      session_id: context[:session_id]
    })

    # Call agent with signal
    case Jido.Agent.call(agent, signal) do
      {:ok, updated_agent, directives} ->
        # Extract results from directives
        result = extract_result(directives)
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

### 5.2.1.2: Add Signal Creation
- [ ] Create ToolCall signal from tool_call
- [ ] Set proper source
- [ ] Include all context

### 5.2.1.3: Add Result Extraction
- [ ] Extract result from directives
- [ ] Handle timeout directives
- [ ] Handle error directives

---

## 5.2.2: Add Compatibility Layer

Maintain old executor API during migration.

### 5.2.2.1: Update Legacy Executor
- [ ] Open `lib/jido_code_core/tools/executor.ex`
- [ ] Add feature flag for new executor
- [ ] Delegate to AgentExecutor when enabled

```elixir
def execute(tool_call, opts \\ []) do
  if Application.get_env(:jido_code_core, :agent_executor_enabled, false) do
    AgentExecutor.execute(tool_call, opts)
  else
    # Legacy execution path
    execute_legacy(tool_call, opts)
  end
end
```

### 5.2.2.2: Maintain Legacy Path
- [ ] Keep existing execution logic
- [ ] Add deprecation warning
- [ ] Document migration path

---

## Phase 5.2 Success Criteria

1. **AgentExecutor**: New executor working
2. **Compatibility**: Legacy API still works
3. **Feature Flag**: Can toggle between executors
4. **Results**: Both produce same results
5. **Tests**: All executor tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/tools/agent_executor.ex` | ~200 (new) | New executor |
| `lib/jido_code_core/tools/executor.ex` | +30 | Add compatibility |

## Rollback Plan

```bash
rm -f lib/jido_code_core/tools/agent_executor.ex
git checkout lib/jido_code_core/tools/executor.ex
```

Proceed to [Section 5.3: Tool Actions](./03-tool-actions.md)
