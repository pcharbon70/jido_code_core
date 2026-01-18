# Phase 4.3: LLM Skill Integration

Integrate Jido.AI LLM skill with CodeSessionAgent for code assistance.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    LLM Skill Integration                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              CodeSessionAgent                            │  │
│   │  skills: [                                               │  │
│   │    ...,                                                  │  │
│   │    {Jido.AI.Skills.LLM, [                                │  │
│   │      default_model: :capable,                            │  │
│   │      default_max_tokens: 4096,                           │  │
│   │      adapter: JidoCode.AI.CodeAdapter                    │  │
│   │    ]}                                                     │  │
│   │  ]                                                        │  │
│   │  strategy: Jido.Agent.Strategy.React                      │  │
│   └─────────────────────────────────────────────────────────┘  │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                    ReAct Loop                             │  │
│   │  1. Receive user prompt                                 │  │
│   │  2. LLM generates thought + tool call                   │  │
│   │  3. Execute tool via signal                              │  │
│   │  4. Return result to LLM                                 │  │
│   │  5. Repeat until done                                    │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/agent/code_session.ex` | Add LLM skill |
| `lib/jido_code_core/ai/code_adapter.ex` | Custom LLM adapter (optional) |

---

## 4.3.1: Mount Jido.AI.Skills.LLM

Add LLM skill to CodeSessionAgent.

### 4.3.1.1: Update CodeSessionAgent Skills
- [ ] Open `lib/jido_code_core/agent/code_session.ex`
- [ ] Add LLM skill to skills list

```elixir
defmodule JidoCodeCore.Agent.CodeSession do
  use Jido.Agent,
    # ... other config
    skills: [
      JidoCodeCore.Skills.FileSystem,
      JidoCodeCore.Skills.Memory,
      JidoCodeCore.Skills.Tools,
      {Jido.AI.Skills.LLM, [
        default_model: :capable,
        default_max_tokens: 4096,
        default_temperature: 0.7
      ]}
    ]
end
```

### 4.3.1.2: Configure Model Defaults
- [ ] Set default model for code tasks
- [ ] Configure max_tokens for responses
- [ ] Set temperature for code generation

### 4.3.1.3: Connect LLM Config to Session
- [ ] Read LLM config from session state
- [ ] Pass to LLM skill on mount
- [ ] Handle config changes

---

## 4.3.2: Add ReAct Strategy

Switch from Direct to ReAct strategy for tool calling.

### 4.3.2.1: Update Agent Strategy
- [ ] Change from Direct to ReAct
- [ ] Configure ReAct parameters

```elixir
defmodule JidoCodeCore.Agent.CodeSession do
  use Jido.Agent,
    strategy: {Jido.Agent.Strategy.React, [
      max_iterations: 10,
      thought_prompt: "Think step by step about what code changes are needed.",
      tools_prompt: "Available tools: {{tools}}"
    ]}
end
```

### 4.3.2.2: Add Prompt Templates
- [ ] Create system prompt for code assistance
- [ ] Add tool descriptions to prompt
- [ ] Include context from working_context

### 4.3.2.3: Configure Tool Calling
- [ ] Map tools to LLM function calling format
- [ ] Add tool schemas to LLM context
- [ ] Handle tool execution results

---

## 4.3.3: Create Custom Code Adapter (Optional)

Custom adapter for code-specific LLM behavior.

### 4.3.3.1: Create CodeAdapter Module
- [ ] Create `lib/jido_code_core/ai/code_adapter.ex`
- [ ] Extend Jido.AI.Adapters.Default
- [ ] Add code-specific prompt handling

```elixir
defmodule JidoCodeCore.AI.CodeAdapter do
  use Jido.AI.Adapter,
    adapter_type: :code_assistant

  def preprocess_prompt(prompt, context) do
    # Add code context to prompt
    language = context.agent.state[:language]
    working_context = context.agent.state[:working_context]

    """
    You are a code assistant for #{language} projects.

    Context:
    #{format_context(working_context)}

    User: #{prompt}
    """
  end
end
```

### 4.3.3.2: Add Context Formatting
- [ ] Format working_context for prompt
- [ ] Include recent file operations
- [ ] Add project structure summary

### 4.3.3.3: Create Adapter Tests
- [ ] Test prompt formatting
- [ ] Test context inclusion
- [ ] Verify tool calling works

---

## Phase 4.3 Success Criteria

1. **LLM Skill**: LLM skill mounted in CodeSessionAgent
2. **Configuration**: LLM config connected to session
3. **ReAct**: Strategy working for tool calling
4. **Adapter**: Code adapter formatting prompts
5. **Tests**: LLM integration tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/agent/code_session.ex` | +30 | Add LLM skill |
| `lib/jido_code_core/ai/code_adapter.ex` | ~100 (new) | Custom adapter |
| `test/jido_code_core/agent/llm_integration_test.exs` | ~150 (new) | Tests |

## Rollback Plan

```bash
git checkout lib/jido_code_core/agent/code_session.ex
rm -f lib/jido_code_core/ai/code_adapter.ex
rm -f test/jido_code_core/agent/llm_integration_test.exs
```

## Phase 4 Success Criteria

1. **Actions**: All actions use Zoi schemas
2. **FileSystemSkill**: File operations as skill
3. **MemorySkill**: Memory operations as skill
4. **LLM Skill**: Jido.AI LLM integrated
5. **ReAct**: Strategy working for tool calling

Proceed to [Phase 5: Tool Integration](../phase05_tool_integration/overview.md)
