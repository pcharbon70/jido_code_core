# Phase 4.2: Skill Extraction

Extract tool handlers into composable Jido.Skill modules.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Skill Architecture                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                    Jido.Skill                             │  │
│   │  • name: "skill_name"                                    │  │
│   │  • state_key: :skill_state                                │  │
│   │  • actions: [Action1, Action2, ...]                       │  │
│   │  • schema: Zoi.object(%{skill_state_fields})             │  │
│   │  • callbacks: mount/2, router/1, child_spec/1            │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│   State Isolation:                                               │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────────────┐  │
│   │ FileSystem  │   │ Memory      │   │ Tools               │  │
│   │ state_key:  │   │ state_key:  │   │ state_key:          │  │
│   │ :file_system│   │ :memory     │   │ :tools              │  │
│   └─────────────┘   └─────────────┘   └─────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/skills/file_system.ex` | File operations skill |
| `lib/jido_code_core/skills/memory.ex` | Memory operations skill |
| `lib/jido_code_core/skills/tools.ex` | Tools aggregate skill |

---

## 4.2.1: Create FileSystemSkill

Extract file operations into a composable skill.

### 4.2.1.1: Define FileSystemSkill
- [ ] Create `lib/jido_code_core/skills/file_system.ex`
- [ ] Add skill configuration

```elixir
defmodule JidoCodeCore.Skills.FileSystem do
  use Jido.Skill,
    name: "file_system",
    state_key: :file_system,
    description: "File system operations for code editing",
    category: "code",
    actions: [
      JidoCodeCore.Actions.ReadFile,
      JidoCodeCore.Actions.WriteFile,
      JidoCodeCore.Actions.ListDir,
      JidoCodeCore.Actions.GlobSearch
    ],
    schema: Zoi.object(%{
      tracked_reads: Zoi.list(Zoi.string())
        |> Zoi.default([])
        |> Zoi.description("Tracked file reads"),
      tracked_writes: Zoi.list(Zoi.string())
        |> Zoi.default([])
        |> Zoi.description("Tracked file writes"),
      project_root: Zoi.string()
        |> Zoi.default(nil)
        |> Zoi.description("Project root path")
    }),
    signal_patterns: ["jido_code.file.*"]
end
```

### 4.2.1.2: Add mount/2 Callback
- [ ] Initialize file tracking state
- [ ] Validate project_root from context
- [ ] Return initial state

### 4.2.1.3: Add router/1 Callback
- [ ] Map file signals to actions
- [ ] Add routing rules

### 4.2.1.4: Create FileSystemSkill Tests
- [ ] Test skill mounting
- [ ] Test state isolation
- [ ] Test action routing

---

## 4.2.2: Create MemorySkill

Extract memory operations into a composable skill.

### 4.2.2.1: Define MemorySkill
- [ ] Create `lib/jido_code_core/skills/memory.ex`
- [ ] Add skill configuration

```elixir
defmodule JidoCodeCore.Skills.Memory do
  use Jido.Skill,
    name: "memory",
    state_key: :memory,
    description: "Memory operations for storing and recalling information",
    category: "memory",
    actions: [
      JidoCodeCore.Memory.Actions.Remember,
      JidoCodeCore.Memory.Actions.Recall,
      JidoCodeCore.Memory.Actions.Forget
    ],
    schema: Zoi.object(%{
      pending_memories: Zoi.list(Zoi.any())
        |> Zoi.default([]),
      access_log: Zoi.map(Zoi.any(), Zoi.any())
        |> Zoi.default(%{}),
      working_context: Zoi.map(Zoi.any(), Zoi.any())
        |> Zoi.default(%{})
    }),
    signal_patterns: ["jido_code.memory.*"]
end
```

### 4.2.2.2: Add mount/2 Callback
- [ ] Initialize memory tracking state
- [ ] Set up access tracking
- [ ] Return initial state

### 4.2.2.3: Add router/1 Callback
- [ ] Map memory signals to actions
- [ ] Add routing rules

### 4.2.2.4: Create MemorySkill Tests
- [ ] Test skill mounting
- [ ] Test state isolation
- [ ] Test action routing

---

## 4.2.3: Create ToolSkill

Create aggregate skill for all tools.

### 4.2.3.1: Define ToolSkill
- [ ] Create `lib/jido_code_core/skills/tools.ex`
- [ ] Add skill configuration

```elixir
defmodule JidoCodeCore.Skills.Tools do
  use Jido.Skill,
    name: "tools",
    state_key: :tools,
    description: "Code editing tools",
    category: "tools",
    actions: [
      # Tool actions will be added here in Phase 5
    ],
    schema: Zoi.object(%{
      enabled_tools: Zoi.list(Zoi.string())
        |> Zoi.default([]),
      execution_stats: Zoi.map(Zoi.string(), Zoi.any())
        |> Zoi.default(%{})
    }),
    signal_patterns: ["jido_code.tool.*"]
end
```

### 4.2.3.2: Add Tool Discovery
- [ ] Auto-discover tool definitions
- [ ] Register tool actions dynamically
- [ ] Handle tool metadata

### 4.2.3.3: Create ToolSkill Tests
- [ ] Test skill mounting
- [ ] Test tool discovery
- [ ] Test tool routing

---

## Phase 4.2 Success Criteria

1. **FileSystemSkill**: File operations as skill
2. **MemorySkill**: Memory operations as skill
3. **ToolSkill**: Tools aggregate skill created
4. **State Isolation**: Each skill has isolated state
5. **Tests**: All skill tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/skills/file_system.ex` | ~150 (new) | File skill |
| `lib/jido_code_core/skills/memory.ex` | ~150 (new) | Memory skill |
| `lib/jido_code_core/skills/tools.ex` | ~100 (new) | Tools skill |
| `test/jido_code_core/skills/` | ~300 (new) | Tests |

## Rollback Plan

```bash
rm -rf lib/jido_code_core/skills/
rm -rf test/jido_code_core/skills/
```

Proceed to [Section 4.3: LLM Skill](./03-llm-skill.md)
