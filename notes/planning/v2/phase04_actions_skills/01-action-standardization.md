# Phase 4.1: Action Standardization

Ensure all actions follow Jido.Action conventions with Zoi schemas.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  Action Schema Migration                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Current (NimbleOptions)          Target (Zoi)                  │
│   ──────────────────────           ─────────────                │
│                                                                  │
│   use Jido.Action,                  use Jido.Action,             │
│     schema: [                         schema: Zoi.object(%{      │
│       content: [                     content: Zoi.string(        │
│         type: :string,                 required: true,          │
│         required: true                description: "..."        │
│       ]                              ])                         │
│     ]                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/memory/actions/*.ex` | Memory action schemas |

---

## 4.1.1: Audit Memory Actions

Review current action implementations.

### 4.1.1.1: Review Remember Action
- [ ] Read `lib/jido_code_core/memory/actions/remember.ex`
- [ ] Document current schema
- [ ] Identify Zoi migration requirements

### 4.1.1.2: Review Recall Action
- [ ] Read `lib/jido_code_core/memory/actions/recall.ex`
- [ ] Document current schema
- [ ] Identify Zoi migration requirements

### 4.1.1.3: Review Forget Action
- [ ] Read `lib/jido_code_core/memory/actions/forget.ex`
- [ ] Document current schema
- [ ] Identify Zoi migration requirements

---

## 4.1.2: Migrate Action Schemas to Zoi

Convert NimbleOptions schemas to Zoi.

### 4.1.2.1: Update Remember Action Schema
- [ ] Convert to Zoi.object pattern
- [ ] Add proper descriptions
- [ ] Set appropriate defaults

```elixir
# Before
use Jido.Action,
  schema: [
    content: [type: :string, required: true],
    type: [type: :atom, default: :fact],
    confidence: [type: :float, default: 0.5],
    rationale: [type: :string, required: false]
  ]

# After
use Jido.Action,
  schema: Zoi.object(%{
    content: Zoi.string(
      required: true,
      description: "The content to remember"
    ),
    type: Zoi.atom(
      default: :fact,
      description: "Type of memory (fact, pattern, discovery)"
    ),
    confidence: Zoi.float(
      default: 0.5,
      description: "Confidence level (0.0 to 1.0)"
    ),
    rationale: Zoi.string(
      optional: true,
      description: "Reasoning for this memory"
    )
  })
```

### 4.1.2.2: Update Recall Action Schema
- [ ] Convert to Zoi.object pattern
- [ ] Add proper descriptions
- [ ] Set appropriate defaults

### 4.1.2.3: Update Forget Action Schema
- [ ] Convert to Zoi.object pattern
- [ ] Add proper descriptions
- [ ] Set appropriate defaults

---

## 4.1.3: Test Action Validation

Verify schema validation works correctly.

### 4.1.3.1: Test Remember Validation
- [ ] Test valid Remember parameters
- [ ] Test missing required fields
- [ ] Test invalid confidence values
- [ ] Test type coercion

### 4.1.3.2: Test Recall Validation
- [ ] Test valid Recall parameters
- [ ] Test query validation
- [ ] Test limit validation

### 4.1.3.3: Test Forget Validation
- [ ] Test valid Forget parameters
- [ ] Test memory_id validation
- [ ] Test reason validation

---

## Phase 4.1 Success Criteria

1. **Audit**: All actions documented
2. **Schemas**: All actions use Zoi schemas
3. **Validation**: Schema validation working
4. **Tests**: All action tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/memory/actions/remember.ex` | ~30 | Update schema |
| `lib/jido_code_core/memory/actions/recall.ex` | ~30 | Update schema |
| `lib/jido_code_core/memory/actions/forget.ex` | ~30 | Update schema |

## Rollback Plan

```bash
git checkout lib/jido_code_core/memory/actions/
```

Proceed to [Section 4.2: Skill Extraction](./02-skill-extraction.md)
