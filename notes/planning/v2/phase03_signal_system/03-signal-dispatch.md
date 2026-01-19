# Phase 3.3: Signal Dispatch Integration

Integrate with Jido.Signal.Dispatch for signal distribution.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      Signal Dispatch Flow                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌────────────────┐                                                  │
│   │ Jido.Agent     │                                                  │
│   │ cmd/2          │─────Directive.Emit────────> Signal                │
│   └────────────────┘                           │                        │
│                                                  │                        │
│                                                  ▼                        │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                   Jido.Signal.Dispatch                          │    │
│   │  • Route signals to subscribers                                 │    │
│   │  • Handle pattern matching                                      │    │
│   │  • Manage subscriptions                                         │    │
│   └────────────────────────────────────────────────────────────────┘    │
│                                                  │                        │
│                                                  ▼                        │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                      Subscribers                               │    │
│   │  • TUI components                                              │    │
│   │  • Logging/Telemetry                                           │    │
│   │  • Other agents                                                │    │
│   └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/signals/dispatch.ex` | Signal dispatch configuration |

---

## 3.3.1: Configure Signal Dispatch

Set up Jido.Signal.Dispatch for the application.

### 3.3.1.1: Configure Dispatch in Application
- [ ] Open `lib/jido_code_core/application.ex`
- [ ] Add Jido.Signal.Dispatch to supervision tree

```elixir
children = [
  # Existing children...
  {Jido.Signal.Dispatch, []}
]
```

### 3.3.1.2: Configure Signal Topics
- [ ] Define application-specific topics
- [ ] Configure topic routing
- [ ] Add subscription management

---

## 3.3.2: Create Signal Subscriptions

Set up subscribers for signal handling.

### 3.3.2.1: Create TUI Signal Subscriber
- [ ] Create `lib/jido_code_core/signals/tui_subscriber.ex`
- [ ] Subscribe to relevant signal types
- [ ] Handle signal updates

### 3.3.2.2: Create Logging Subscriber
- [ ] Create `lib/jido_code_core/signals/logging_subscriber.ex`
- [ ] Log all significant signals
- [ ] Configure log levels

### 3.3.2.3: Create Telemetry Subscriber
- [ ] Create `lib/jido_code_core/signals/telemetry_subscriber.ex`
- [ ] Emit telemetry events
- [ ] Track metrics

---

## 3.3.3: Add Subscription Management

Manage signal lifecycle and subscriptions.

### 3.3.3.1: Add Subscription Helpers
- [ ] Create `subscribe/2` helper
- [ ] Create `unsubscribe/2` helper
- [ ] Create `list_subscriptions/1` helper

### 3.3.3.2: Add Subscription Tests
- [ ] Test subscription lifecycle
- [ ] Test signal delivery
- [ ] Test unsubscription

---

## Phase 3.3 Success Criteria

1. **Dispatch**: Signal dispatch configured
2. **Subscribers**: TUI and logging subscribers working
3. **Tests**: All dispatch tests pass
4. **Integration**: Signals flow correctly through system

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/signals/dispatch.ex` | ~100 (new) | Dispatch config |
| `lib/jido_code_core/signals/tui_subscriber.ex` | ~80 (new) | TUI subscriber |
| `lib/jido_code_core/signals/logging_subscriber.ex` | ~60 (new) | Logging |
| `lib/jido_code_core/application.ex` | +5 | Add to supervision |
| `test/jido_code_core/signals/dispatch_test.exs` | ~100 (new) | Tests |

## Rollback Plan

```bash
rm -f lib/jido_code_core/signals/dispatch.ex
rm -f lib/jido_code_core/signals/tui_subscriber.ex
rm -f lib/jido_code_core/signals/logging_subscriber.ex
git checkout lib/jido_code_core/application.ex
rm -f test/jido_code_core/signals/dispatch_test.exs
```

## Phase 3 Success Criteria

1. **Signals**: All signal types defined
2. **Routing**: Signal routes working
3. **Dispatch**: Signal dispatch integrated
4. **Tests**: All signal system tests pass

Proceed to [Phase 4: Actions & Skills](../phase04_actions_skills/overview.md)
