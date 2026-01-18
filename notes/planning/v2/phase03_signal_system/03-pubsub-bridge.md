# Phase 3.3: PubSub Bridge

Create a bidirectional bridge between Jido.Signal and Phoenix.PubSub for backward compatibility.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        PubSub Bridge Architecture                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌────────────────┐                                                  │
│   │ Jido.Agent     │                                                  │
│   │ cmd/2          │─────Directive.Emit────────> Signal                │
│   └────────────────┘                           │                        │
│                                                  │                        │
│                                                  ▼                        │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                      PubSubBridge                              │    │
│   │  Subscribes to Jido.Signal.Dispatch                            │    │
│   │  Re-emits to Phoenix.PubSub (dual topics)                       │    │
│   └────────────────────────────────────────────────────────────────┘    │
│                                                  │                        │
│                                                  │ Phoenix.PubSub         │
│                                                  ▼                        │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │                   Existing Subscribers                         │    │
│   │  • TUI events (tui.events.{session_id})                        │    │
│   │  • Global events (tui.events)                                   │    │
│   └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│   ┌────────────────┐     Phoenix.PubSub     ┌────────────────┐          │
│   │ Legacy Code    │<──────broadcast────────│ PubSubAdapter   │          │
│   │                │                       │ Signal──────────>│          │
│   └────────────────┘                       └────────────────┘            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `lib/jido_code_core/signals/pubsub_bridge.ex` | Signal → PubSub adapter |
| `lib/jido_code_core/signals/pubsub_adapter.ex` | PubSub → Signal adapter |

---

## 3.3.1: Implement Signal-to-PubSub Adapter

Create adapter that subscribes to Jido.Signal.Dispatch and re-emits to PubSub.

### 3.3.1.1: Create PubSubBridge Module
- [ ] Create `lib/jido_code_core/signals/pubsub_bridge.ex`
- [ ] Create GenServer that subscribes to Jido.Signal.Dispatch
- [ ] Handle signal dispatch messages

```elixir
defmodule JidoCodeCore.Signals.PubSubBridge do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    # Subscribe to Jido.Signal.Dispatch
    Phoenix.PubSub.subscribe(Jido.Signal.Dispatch, "signals")

    {:ok, %{pubsub: Keyword.get(opts, :pubsub, JidoCode.PubSub)}}
  end

  def handle_info(%Jido.Signal{} = signal, state) do
    # Re-emit to Phoenix.PubSub
    broadcast_to_pubsub(signal, state.pubsub)
    {:noreply, state}
  end
end
```

### 3.3.1.2: Add Dual-Topic Broadcasting
- [ ] Implement ARCH-2 dual-topic pattern
- [ ] Broadcast to session-specific topic
- [ ] Broadcast to global topic
- [ ] Include session_id in payload

```elixir
defp broadcast_to_pubsub(%Jido.Signal{} = signal, pubsub) do
  session_id = signal.data[:session_id]

  # Session-specific topic
  session_topic = "tui.events.#{session_id}"
  Phoenix.PubSub.broadcast(pubsub, session_topic, signal_to_message(signal))

  # Global topic (with session_id in payload)
  global_topic = "tui.events"
  Phoenix.PubSub.broadcast(pubsub, global_topic, signal_to_message(signal))
end
```

### 3.3.1.3: Add Signal to Message Conversion
- [ ] Convert Jido.Signal to legacy message format
- [ ] Map signal type to message type
- [ ] Include all relevant data

---

## 3.3.2: Create PubSub-to-Signal Adapter

Create adapter for legacy code to send signals via PubSub.

### 3.3.2.1: Create PubSubAdapter Module
- [ ] Create `lib/jido_code_core/signals/pubsub_adapter.ex`
- [ ] Add `broadcast/2` function for legacy code
- [ ] Convert PubSub messages to Jido.Signal

```elixir
defmodule JidoCodeCore.Signals.PubSubAdapter do
  @doc """
  Broadcast a signal via Phoenix.PubSub (legacy interface).

  Converts the signal and emits to both Jido.Signal.Dispatch
  and Phoenix.PubSub for compatibility.
  """
  def broadcast(%Jido.Signal{} = signal, opts \\ []) do
    # Emit to Jido.Signal.Dispatch
    Jido.Signal.Dispatch.emit(signal)

    # Also emit to PubSub for legacy subscribers
    session_id = signal.data[:session_id]
    PubSubHelpers.broadcast(session_id, signal_to_message(signal))
  end
end
```

### 3.3.2.2: Add Legacy Message Conversion
- [ ] Convert `{:tool_call, ...}` to ToolCall signal
- [ ] Convert `{:tool_result, ...}` to ToolResult signal
- [ ] Convert other legacy message types

### 3.3.2.3: Add Signal Validation
- [ ] Validate converted signals
- [ ] Handle invalid messages gracefully
- [ ] Log conversion errors

---

## 3.3.3: Add Bridge to Supervision Tree

Integrate the bridge into the application supervision tree.

### 3.3.3.1: Update Application Children
- [ ] Open `lib/jido_code_core/application.ex`
- [ ] Add PubSubBridge to children list

```elixir
children = [
  # Existing children...
  {JidoCodeCore.Signals.PubSubBridge, [pubsub: JidoCode.PubSub]}
]
```

### 3.3.3.2: Add Bridge Configuration
- [ ] Add config for enabling/disabling bridge
- [ ] Add config for pubsub backend

---

## Phase 3.3 Success Criteria

1. **Bridge**: PubSubBridge functional
2. **Adapter**: PubSubAdapter working
3. **Dual-Topic**: ARCH-2 dual-topic pattern maintained
4. **Backward Compat**: Existing subscribers receive events
5. **Tests**: All bridge tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `lib/jido_code_core/signals/pubsub_bridge.ex` | ~150 (new) | Bridge module |
| `lib/jido_code_core/signals/pubsub_adapter.ex` | ~100 (new) | Adapter module |
| `lib/jido_code_core/application.ex` | +5 | Add to supervision |
| `test/jido_code_core/signals/pubsub_bridge_test.exs` | ~150 (new) | Tests |

## Rollback Plan

```bash
rm -f lib/jido_code_core/signals/pubsub_bridge.ex
rm -f lib/jido_code_core/signals/pubsub_adapter.ex
git checkout lib/jido_code_core/application.ex
rm -f test/jido_code_core/signals/pubsub_bridge_test.exs
```

## Phase 3 Success Criteria

1. **Signals**: All signal types defined
2. **Routing**: Signal routes working
3. **Bridge**: PubSub bridge functional
4. **Backward Compatibility**: Existing subscribers still receive events
5. **Tests**: All signal system tests pass

Proceed to [Phase 4: Actions & Skills](../phase04_actions_skills/overview.md)
