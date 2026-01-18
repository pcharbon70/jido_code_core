# Phase 7.2: Promotion Engine

Migrate promotion engine to use StateOps and Actions.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   Promotion Engine Architecture                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                    PromotionSkill                          │  │
│   │  • Schedule: Periodic promotion runs                     │  │
│   │  • Triggers: Memory limit, time-based, agent decision     │  │
│   │  • Engine: Scoring and selection logic                    │  │
│   └─────────────────────────────────────────────────────────┘  │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                Promotion Flow                              │  │
│   │  1. Check pending memories                                │  │
│   │  2. Score candidates (importance + access)               │  │
│   │  3. Select above threshold                                │  │
│   │  4. Store to TripleStore                                  │  │
│   │  5. Emit PromotionSignal                                   │  │
│   │  6. Update StateOps                                       │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/skills/promotion.ex` | Promotion skill |
| `lib/jido_code_core/actions/run_promotion.ex` | Promotion action |
| `lib/jido_code_core/memory/promotion/engine.ex` | Update engine |

---

## 7.2.1: Create PromotionSkill

Package promotion as a composable skill.

### 7.2.1.1: Define PromotionSkill
- [ ] Create `lib/jido_code_core/skills/promotion.ex`

```elixir
defmodule JidoCodeCore.Skills.Promotion do
  use Jido.Skill,
    name: "promotion",
    state_key: :promotion,
    description: "Automatic memory promotion to long-term storage",
    category: "memory",
    actions: [
      JidoCodeCore.Actions.RunPromotion
    ],
    schema: Zoi.object(%{
      enabled: Zoi.boolean() |> Zoi.default(true),
      interval_ms: Zoi.integer() |> Zoi.default(30_000),
      last_run: Zoi.any() |> Zoi.default(nil),
      total_promoted: Zoi.integer() |> Zoi.default(0),
      runs: Zoi.integer() |> Zoi.default(0)
    }),
    schedules: [
      {"*/1 * * * *", JidoCodeCore.Actions.RunPromotion}
    ]
end
```

### 7.2.1.2: Add mount/2 Callback
- [ ] Initialize promotion state
- [ ] Schedule periodic runs
- [ ] Set up timer

### 7.2.1.3: Add child_spec/1
- [ ] Return promotion timer child spec
- [ ] Configure timer interval

---

## 7.2.2: Convert Promotion to Action

Create RunPromotion action.

### 7.2.2.1: Create RunPromotion Action
- [ ] Create `lib/jido_code_core/actions/run_promotion.ex`

```elixir
defmodule JidoCodeCore.Actions.RunPromotion do
  use Jido.Action,
    name: "run_promotion",
    description: "Execute memory promotion cycle"

  def run(_params, context) do
    # Build state from context
    promotion_state = build_promotion_state(context)

    # Run promotion engine
    case PromotionEngine.run_with_state(promotion_state, context.session_id, []) do
      {:ok, count, promoted_ids} when count > 0 ->
        # Return StateOps for state updates
        # Return Directive.Emit for signal
        {:ok, %{promoted: count, ids: promoted_ids}}

      {:ok, 0, []} ->
        {:ok, %{promoted: 0}}
    end
  end
end
```

### 7.2.2.2: Update Promotion Engine
- [ ] Open `lib/jido_code_core/memory/promotion/engine.ex`
- [ ] Update to return StateOps
- [ ] Add Directive.Emit for signals

### 7.2.2.3: Create Promotion Action Tests
- [ ] Test action execution
- [ ] Verify StateOps returned
- [ ] Verify signals emitted

---

## 7.2.3: Update Promotion Triggers

Migrate trigger system to use StateOps.

### 7.2.3.1: Update Triggers Module
- [ ] Open `lib/jido_code_core/memory/promotion/triggers.ex`
- [ ] Update to emit signals
- [ ] Add StateOps for state updates

### 7.2.3.2: Add Trigger Signal Types
- [ ] MemoryLimitReached signal
- [ ] AgentDecision signal
- [ ] TimerExpired signal

### 7.2.3.3: Create Trigger Tests
- [ ] Test limit trigger
- [ ] Test agent decision trigger
- [ ] Test timer trigger

---

## Phase 7.2 Success Criteria

1. **PromotionSkill**: Skill defined and working
2. **Action**: RunPromotion action functional
3. **Engine**: Updated to use StateOps
4. **Triggers**: Emit signals correctly
5. **Tests**: All promotion tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/skills/promotion.ex` | ~150 (new) | Skill |
| `lib/jido_code_core/actions/run_promotion.ex` | ~100 (new) | Action |
| `lib/jido_code_core/memory/promotion/engine.ex` | ~80 | Update |
| `lib/jido_code_core/memory/promotion/triggers.ex` | ~60 | Update |
| `test/jido_code_core/skills/promotion_test.exs` | ~150 (new) | Tests |

## Rollback Plan

```bash
rm -f lib/jido_code_core/skills/promotion.ex
rm -f lib/jido_code_core/actions/run_promotion.ex
git checkout lib/jido_code_core/memory/promotion/
rm -f test/jido_code_core/skills/promotion_test.exs
```

Proceed to [Section 7.3: TripleStore Integration](./03-triplestore-integration.md)
