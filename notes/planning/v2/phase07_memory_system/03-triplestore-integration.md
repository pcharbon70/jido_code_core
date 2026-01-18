# Phase 7.3: TripleStore Integration

Keep TripleStore as backend with action-based access.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  TripleStore Access Pattern                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                   Memory Actions                           │  │
│   │  Remember → TripleStoreAction.Store                      │  │
│   │  Recall → TripleStoreAction.Query                         │  │
│   │  Forget → TripleStoreAction.SoftDelete                    │  │
│   └─────────────────────────────────────────────────────────┘  │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │              TripleStore Backend                          │  │
│   │  • Storage: Long-term memory                              │  │
│   │  • Query: Semantic search                                │  │
│   │  • Update: Modify existing triples                        │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/actions/triple_store/*.ex` | TripleStore actions |
| `lib/jido_code_core/knowledge_graph/store.ex` | Backend (existing) |

---

## 7.3.1: Create TripleStore Actions

Actions for TripleStore access.

### 7.3.1.1: Create StoreTriple Action
- [ ] Create `lib/jido_code_core/actions/triple_store/store.ex`

```elixir
defmodule JidoCodeCore.Actions.TripleStore.Store do
  use Jido.Action,
    name: "store_triple",
    description: "Store a triple in the knowledge graph"

  @schema Zoi.object(%{
    subject: Zoi.string(required: true),
    predicate: Zoi.string(required: true),
    object: Zoi.string(required: true)
  })

  def run(params, context) do
    case JidoCodeCore.KnowledgeGraph.Store.put(params, context) do
      {:ok, triple} ->
        # Return StateOp for tracking
        # Emit MemoryStored signal
        {:ok, triple}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

### 7.3.1.2: Create QueryTriple Action
- [ ] Create `lib/jido_code_core/actions/triple_store/query.ex`
- [ ] Add query parameters
- [ ] Return results

### 7.3.1.3: Create UpdateTriple Action
- [ ] Create `lib/jido_code_core/actions/triple_store/update.ex`
- [ ] Add update parameters
- [ ] Handle updates

---

## 7.3.2: Emit Memory Signals

Add signal emission to memory actions.

### 7.3.2.1: Update Remember Action
- [ ] Open `lib/jido_code_core/memory/actions/remember.ex`
- [ ] Add Directive.Emit for MemoryStored signal
- [ ] Return StateOps for pending memory

### 7.3.2.2: Update Recall Action
- [ ] Open `lib/jido_code_core/memory/actions/recall.ex`
- [ ] Add Directive.Emit for MemoryRecalled signal
- [ ] Update access log

### 7.3.2.3: Update Forget Action
- [ ] Open `lib/jido_code_core/memory/actions/forget.ex`
- [ ] Add Directive.Emit for MemoryForgotten signal
- [ ] Update TripleStore

---

## 7.3.3: Create TripleStore Tests

Test TripleStore integration.

### 7.3.3.1: Test Store Action
- [ ] Test triple storage
- [ ] Verify signal emission
- [ ] Check state updates

### 7.3.3.2: Test Query Action
- [ ] Test query execution
- [ ] Verify results format
- [ ] Check access log update

### 7.3.3.3: Test Update Action
- [ ] Test triple updates
- [ ] Verify modifications
- [ ] Check signal emission

---

## Phase 7.3 Success Criteria

1. **Actions**: TripleStore actions created
2. **Signals**: Memory actions emit signals
3. **Integration**: TripleStore backend working
4. **StateOps**: State updates using StateOps
5. **Tests**: All TripleStore tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/actions/triple_store/*.ex` | ~300 (new) | Actions |
| `lib/jido_code_core/memory/actions/*.ex` | ~60 | Update |
| `test/jido_code_core/actions/triple_store/*_test.exs` | ~200 (new) | Tests |

## Rollback Plan

```bash
rm -rf lib/jido_code_core/actions/triple_store/
git checkout lib/jido_code_core/memory/actions/
rm -rf test/jido_code_core/actions/triple_store/
```

## Phase 7 Success Criteria

1. **MemorySkill**: Core memory operations as skill
2. **PromotionSkill**: Promotion engine working
3. **TripleStore**: Backend actions functional
4. **Integration**: All memory tests pass
5. **StateIsolation**: Memory state properly isolated

Proceed to [Phase 8: Testing & Cleanup](../phase08_testing_cleanup/overview.md)
