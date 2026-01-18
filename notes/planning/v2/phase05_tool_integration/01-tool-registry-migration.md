# Phase 5.1: Tool Registry Migration

Map existing tools to Jido.Action modules.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Tool to Action Mapping                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Tool Definition               Action Wrapper                    │
│   ────────────────────           ──────────────                  │
│                                                                  │
│   %Tool{                          defmodule Actions.ReadFile do   │
│     name: "read_file",              use Jido.Action,             │
│     handler: FileSystem,            schema: Zoi.object(%{       │
│     schema: %{...}                    path: Zoi.string()         │
│   }                                })                           │
│                                    def run(params, context) do  │
│             ──────────>              FileSystem.read(params)      │
│                                    end                            │
│                                                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/actions/tools/` | Tool action wrappers |
| `lib/jido_code_core/tools/registry.ex` | Existing registry (reference) |

---

## 5.1.1: Map Tools to Actions

Create action wrappers for existing tools.

### 5.1.1.1: Create Actions Directory
- [ ] Create `lib/jido_code_core/actions/tools/` directory

### 5.1.1.2: Create ReadFile Action
- [ ] Create `lib/jido_code_core/actions/tools/read_file.ex`
- [ ] Wrap FileSystem handler

```elixir
defmodule JidoCodeCore.Actions.Tools.ReadFile do
  use Jido.Action,
    name: "read_file",
    description: "Read the contents of a file"

  @schema Zoi.object(%{
    path: Zoi.string(
      required: true,
      description: "Absolute path to file"
    )
  })

  def run(params, context) do
    # Delegate to existing handler
    JidoCodeCore.Tools.Handlers.FileSystem.read(params, context)
  end
end
```

### 5.1.1.3: Create WriteFile Action
- [ ] Create `lib/jido_code_core/actions/tools/write_file.ex`
- [ ] Wrap FileSystem handler
- [ ] Add validation

### 5.1.1.4: Create ListDir Action
- [ ] Create `lib/jido_code_core/actions/tools/list_dir.ex`
- [ ] Wrap FileSystem handler

### 5.1.1.5: Create GlobSearch Action
- [ ] Create `lib/jido_code_core/actions/tools/glob_search.ex`
- [ ] Wrap Search handler

### 5.1.1.6: Create GitCommand Action
- [ ] Create `lib/jido_code_core/actions/tools/git_command.ex`
- [ ] Wrap Git handler

### 5.1.1.7: Create Shell Action
- [ ] Create `lib/jido_code_core/actions/tools/shell.ex`
- [ ] Wrap Shell handler
- [ ] Add security considerations

---

## 5.1.2: Create ToolSkill

Aggregate skill for all tool actions.

### 5.1.2.1: Update ToolSkill Definition
- [ ] Open `lib/jido_code_core/skills/tools.ex`
- [ ] Add all tool actions to actions list

```elixir
defmodule JidoCodeCore.Skills.Tools do
  use Jido.Skill,
    name: "tools",
    state_key: :tools,
    description: "Code editing tools",
    category: "tools",
    actions: [
      # File operations
      JidoCodeCore.Actions.Tools.ReadFile,
      JidoCodeCore.Actions.Tools.WriteFile,
      JidoCodeCore.Actions.Tools.ListDir,
      JidoCodeCore.Actions.Tools.GlobSearch,
      JidoCodeCore.Actions.Tools.FileMultiEdit,

      # Git operations
      JidoCodeCore.Actions.Tools.GitCommand,

      # Shell operations
      JidoCodeCore.Actions.Tools.Shell,

      # Search operations
      JidoCodeCore.Actions.Tools.Search,

      # LSP operations
      JidoCodeCore.Actions.Tools.LSP
    ],
    schema: Zoi.object(%{
      enabled_tools: Zoi.list(Zoi.string()) |> Zoi.default([]),
      execution_stats: Zoi.map(Zoi.string(), Zoi.any()) |> Zoi.default(%{})
    })
end
```

### 5.1.2.2: Add Tool Discovery
- [ ] Auto-discover tools from actions
- [ ] Generate tool metadata
- [ ] Create tool list for LLM

---

## Phase 5.1 Success Criteria

1. **Actions**: All tool actions created
2. **Wrappers**: Handlers wrapped correctly
3. **ToolSkill**: All tools in skill
4. **Discovery**: Tools discoverable
5. **Tests**: Tool action tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/actions/tools/*.ex` | ~800 (new) | Tool actions |
| `lib/jido_code_core/skills/tools.ex` | +50 | Update skill |

## Rollback Plan

```bash
rm -rf lib/jido_code_core/actions/tools/
git checkout lib/jido_code_core/skills/tools.ex
```

Proceed to [Section 5.2: Executor Refactor](./02-executor-refactor.md)
