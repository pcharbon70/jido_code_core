# Phase 1.1: Dependencies & Build

Verify and update all dependencies to ensure compatibility with Jido 2.0.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Dependency Graph                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌──────────┐     ┌──────────┐     ┌──────────────┐      │
│   │ jido     │────>│ jido_ai  │────>│ jido_code_   │      │
│   │ 2.0      │     │ 2.0      │     │ core         │      │
│   └──────────┘     └──────────┘     └──────────────┘      │
│         │                                  │               │
│         v                                  v               │
│   ┌──────────────────────────────────────────────────┐   │
│   │           Transitive Dependencies                │   │
│   │  • zoi (schemas)                                │   │
│   │  • splode (errors)                              │   │
│   │  • fsmx (FSM strategy)                          │   │
│   │  • deep_merge, jason, telemetry                 │   │
│   └──────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Components in This Phase

| File | Purpose |
|------|---------|
| `mix.exs` | Update dependency versions and add new deps |

---

## 1.1.1: Verify Current Jido Dependencies

Ensure Jido framework dependencies are correctly configured.

### 1.1.1.1: Check Jido Dependency Version
- [ ] Read `/home/ducky/code/agentjido/jido_code_core/mix.exs`
- [ ] Verify Jido version is `~> 2.0` or path `../jido`
- [ ] Verify Jido.AI version is `~> 2.0` or path `../jido_ai`
- [ ] Document any version conflicts found

### 1.1.1.2: Run Dependency Check
- [ ] Run `mix deps.clean --all`
- [ ] Run `mix deps.get`
- [ ] Verify no conflicts in dependency resolution
- [ ] Check for any deprecation warnings

### 1.1.1.3: Compile Verification
- [ ] Run `mix compile`
- [ ] Verify Jido.Agent module is available
- [ ] Verify Jido.Signal module is available
- [ ] Verify Jido.Skill module is available
- [ ] Verify Jido.Agent.StateOps module is available

---

## 1.1.2: Add Jido 2.0 Specific Dependencies

Add any new dependencies required for Jido 2.0 patterns.

### 1.1.2.1: Add Zoi Schema Library
- [ ] Add `{:zoi, "~> 0.2"}` if not included via Jido
- [ ] Run `mix deps.get`
- [ ] Verify Zoi compiles

### 1.1.2.2: Add FSMx for Strategy Support
- [ ] Add `{:fsmx, "~> 0.5"}` for FSM strategy support
- [ ] Run `mix deps.get`
- [ ] Verify FSMx compiles

### 1.1.2.3: Verify Splode Availability
- [ ] Check that Splode is included via Jido dependency
- [ ] Verify `Splode.Error` is available
- [ ] Test basic error creation

---

## Phase 1.1 Success Criteria

1. **Dependencies**: `mix deps.get` completes without errors
2. **Compilation**: `mix compile` succeeds with no warnings
3. **Module Availability**: Jido.Agent, Jido.Signal, Jido.Skill are accessible
4. **Test Suite**: All existing tests pass

## Files Modified

| File | Lines Changed | Action |
|------|--------------|--------|
| `mix.exs` | ~5-10 | Update dependency versions |

## Rollback Plan

```bash
git checkout mix.exs
mix deps.clean --all
mix deps.get
```

Proceed to [Section 1.2: Error Handling](./02-error-handling.md)
