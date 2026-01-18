# Phase 4: Actions & Skills - Overview

## Description

Standardize all actions to use Jido.Action conventions and extract tool handlers into composable Jido.Skill modules. This phase also integrates the Jido.AI LLM skill for code assistance.

## Goal

Transform the action and tool system:
1. Standardize all actions with Zoi schemas
2. Extract tool handlers into composable Skills
3. Integrate Jido.AI LLM skill with ReAct strategy

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Actions & Skills Architecture                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                     CodeSessionAgent                             │  │
│   │  skills: [                                                        │  │
│   │    FileSystemSkill,   # File operations                          │  │
│   │    MemorySkill,       # Memory operations                        │  │
│   │    ToolSkill,         # All tools                               │  │
│   │    {Jido.AI.Skills.LLM, [model: capable]}  # LLM integration     │  │
│   │  ]                                                                │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                            │                                           │
│                            ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                    Skill State Isolation                        │  │
│   │  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐  │  │
│   │  │ file_system  │  │ memory       │  │ llm                │  │  │
│   │  │ state        │  │ state        │  │ state              │  │  │
│   │  └──────────────┘  └──────────────┘  └────────────────────┘  │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| Component | Purpose |
|-----------|---------|
| Actions | Standardized actions with Zoi schemas |
| FileSystemSkill | File operations as composable skill |
| MemorySkill | Memory operations as composable skill |
| ToolSkill | Aggregate skill for all tools |
| LLM Skill Integration | Jido.AI LLM with ReAct strategy |

## Phases in This Stage

| Section | Document | Description |
|---------|----------|-------------|
| 4.1 | [01-action-standardization.md](./01-action-standardization.md) | Migrate actions to Zoi |
| 4.2 | [02-skill-extraction.md](./02-skill-extraction.md) | Extract skills |
| 4.3 | [03-llm-skill.md](./03-llm-skill.md) | LLM integration |

## Success Criteria

1. **Actions**: All actions use Zoi schemas
2. **FileSystemSkill**: File operations as skill
3. **MemorySkill**: Memory operations as skill
4. **LLM Skill**: Jido.AI LLM integrated
5. **ReAct**: Strategy working for tool calling

## Dependencies on Previous Phases

- **Phase 1**: Zoi schemas and base types
- **Phase 2**: Agent structure and StateOps
- **Phase 3**: Signal system

## Key References

- [Jido.Action Documentation](../../../jido/lib/jido/action.ex)
- [Jido.Skill Documentation](../../../jido/lib/jido/skill.ex)
- [Jido.AI LLM Skill](../../../jido_ai/lib/jido_ai/skills/llm.ex)

Proceed to [Section 4.1: Action Standardization](./01-action-standardization.md)
