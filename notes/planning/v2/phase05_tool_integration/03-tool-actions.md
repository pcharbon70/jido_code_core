# Phase 5.3: Tool Actions

Convert all tool definitions to action modules.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Tool Definition Migration                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Tool Definition                   Action Module                  │
│   ──────────────────────              ─────────────               │
│                                                                  │
│   defmodule FileRead do              defmodule Actions.ReadFile  │
│     use JidoCodeCore.Tool,             use Jido.Action,          │
│       name: "read_file",                name: "read_file",       │
│       schema: %{...}                   schema: Zoi.object(%{     │
│                                         path: Zoi.string()       │
│     def run(params, context)          })                        │
│       # handler logic                                             │
│     end                                                           │
│   end                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/tools/definitions/*.ex` | Existing definitions (reference) |
| `lib/jido_code_core/actions/tools/*.ex` | New action modules |

---

## 5.3.1: Batch Convert Tool Definitions

Convert all existing tool definitions to actions.

### 5.3.1.1: Convert File Tool Definitions
- [ ] Read `lib/jido_code_core/tools/definitions/file_read.ex`
- [ ] Convert to action in `actions/tools/read_file.ex`
- [ ] Verify parameter mapping

### 5.3.1.2: Convert Edit Tool Definitions
- [ ] Read `lib/jido_code_core/tools/definitions/file_edit.ex`
- [ ] Convert to action in `actions/tools/file_edit.ex`
- [ ] Verify parameter mapping

### 5.3.1.3: Convert Multi-Edit Tool
- [ ] Read `lib/jido_code_core/tools/definitions/file_multi_edit.ex`
- [ ] Convert to action in `actions/tools/file_multi_edit.ex`

### 5.3.1.4: Convert Search Tool Definitions
- [ ] Read search tool definitions
- [ ] Convert to actions
- [ ] Verify query parameter handling

### 5.3.1.5: Convert Git Tool Definitions
- [ ] Read git tool definitions
- [ ] Convert to actions
- [ ] Add command validation

### 5.3.1.6: Convert Shell Tool Definition
- [ ] Read shell tool definition
- [ ] Convert to action
- [ ] Add security layer

### 5.3.1.7: Convert LSP Tool Definitions
- [ ] Read LSP tool definitions
- [ ] Convert to actions
- [ ] Handle LSP client integration

---

## 5.3.2: Create Tool Action Tests

Test all converted tool actions.

### 5.3.2.1: Test File Actions
- [ ] Test ReadFile action
- [ ] Test WriteFile action
- [ ] Test ListDir action
- [ ] Test MultiEdit action

### 5.3.2.2: Test Search Actions
- [ ] Test Search action
- [ ] Test GlobSearch action

### 5.3.2.3: Test Git Action
- [ ] Test GitCommand action
- [ ] Verify command validation

### 5.3.2.4: Test Shell Action
- [ ] Test Shell action
- [ ] Verify security layer

### 5.3.2.5: Test LSP Actions
- [ ] Test LSP actions
- [ ] Verify client integration

---

## 5.3.3: Update ToolSkill

Add all converted actions to ToolSkill.

### 5.3.3.1: Update ToolSkill Actions List
- [ ] Open `lib/jido_code_core/skills/tools.ex`
- [ ] Add all new tool actions

### 5.3.3.2: Verify Tool Discovery
- [ ] Test tool list generation
- [ ] Verify LLM tool format
- [ ] Test tool metadata

---

## Phase 5.3 Success Criteria

1. **Conversion**: All tool definitions converted
2. **Actions**: All actions tested
3. **ToolSkill**: All tools in skill
4. **Discovery**: Tools discoverable by LLM
5. **Tests**: All tool action tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/actions/tools/*.ex` | ~1000 (total) | All tool actions |
| `lib/jido_code_core/skills/tools.ex` | +100 | Update skill |
| `test/jido_code_core/actions/tools/*_test.exs` | ~800 (total) | Tests |

## Rollback Plan

```bash
rm -rf lib/jido_code_core/actions/tools/
git checkout lib/jido_code_core/skills/tools.ex
```

## Phase 5 Success Criteria

1. **Tool Actions**: All tools available as actions
2. **Agent Executor**: Executor using Agent patterns
3. **ToolSkill**: Aggregate skill functional
4. **Tests**: All tool tests pass

Proceed to [Phase 6: Session Migration](../phase06_session_migration/overview.md)
