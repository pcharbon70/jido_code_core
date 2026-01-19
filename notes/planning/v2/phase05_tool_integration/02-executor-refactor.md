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
| `lib/jido_code_core/tools/executor.ex` | Agent-based executor |

---

## 5.2.1: Create Agent-Based Executor

New executor using Agent cmd/2 pattern.

### 5.2.1.1: Refactor Executor Module
- [ ] Open `lib/jido_code_core/tools/executor.ex`
- [ ] Implement execute/2 using Agent cmd/2

```elixir
defmodule JidoCodeCore.Tools.Executor do
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

## Phase 5.2 Success Criteria

1. **Executor**: Agent-based executor working
2. **Signals**: Tool execution via signals
3. **Results**: Results extracted correctly
4. **Tests**: All executor tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/tools/executor.ex` | ~150 | Refactor to Agent |

## Rollback Plan

```bash
git checkout lib/jido_code_core/tools/executor.ex
```

Proceed to [Section 5.3: Tool Actions](./03-tool-actions.md)
