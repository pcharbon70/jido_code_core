# Feature: Phase 1.3 - Base Types (Zoi Schemas)

## Problem Statement

JidoCodeCore needs to define shared base types and schemas for the new architecture using Zoi (the schema validation library from Jido 2.0). These schemas will define the structure of agent state for sessions.

## Solution Overview

1. Created the `lib/jido_code_core/agent/` directory
2. Created `lib/jido_code_core/agent/schemas.ex` with Zoi schema definitions
3. Defined the session agent schema with all required fields
4. Added validation and default value helper functions
5. Wrote comprehensive tests

## Status

**Current Status**: COMPLETE

### Tasks Completed
- [x] Create feature branch
- [x] Create agent directory and schemas module
- [x] Define session_agent_schema
- [x] Add validation and helper functions
- [x] Write tests

## Technical Details

### Files Created
- `lib/jido_code_core/agent/schemas.ex` - Zoi schema definitions
- `test/jido_code_core/agent/schemas_test.exs` - Schema tests (21 tests, 1 skipped)

### Session Agent Schema Fields

**Core Session Fields:**
- `session_id` - Unique session identifier (string, optional)
- `project_path` - Project root path (string, optional)
- `language` - Primary programming language (atom, default: `:elixir`)

**Messages and Conversation:**
- `messages` - Conversation messages (list, default: `[]`)
- `reasoning_steps` - Chain-of-thought steps (list, default: `[]`)
- `tool_calls` - Tool call records (list, default: `[]`)
- `todos` - Task tracking (list, default: `[]`)

**File Tracking:**
- `file_reads` - Tracked file reads (map, default: `%{}`)
- `file_writes` - Tracked file writes (map, default: `%{}`)

**LLM Config:**
- `llm_config` - LLM configuration object with:
  - `provider` - Default: "anthropic"
  - `model` - Default: "claude-3-5-sonnet-20241022"
  - `temperature` - Default: 0.7
  - `max_tokens` - Default: 4096

**Timestamps:**
- `created_at` - Creation timestamp (any, optional)
- `updated_at` - Update timestamp (any, optional)

## Implementation Notes

### Zoi Behavior with Nested Defaults

When Zoi parses nested objects, it only applies defaults for fields that are completely absent from the input. If a nested object is present (e.g., `%{llm_config: %{provider: "openai"}}`), Zoi validates the structure but doesn't automatically apply defaults to missing nested fields.

To work around this, the `ensure_llm_nested_defaults/1` helper function:
1. Checks if `llm_config` is `nil` or empty - applies full defaults
2. For partial configs, merges user-provided values with defaults (user values take precedence)

### Pattern Matching Bug Fix

Initial implementation had a bug where the pattern `%{} = empty_llm_config` matched ANY map (not just empty maps), causing user values to be replaced with defaults. Fixed by changing to `config when map_size(config) == 0`.

## Test Results

```
Finished in 0.5 seconds (0.5s async, 0.00s sync)
21 tests, 0 failures, 1 skipped
```

Full test suite:
```
Finished in 21.7 seconds (2.6s async, 19.1s sync)
61 doctests, 1043 tests, 0 failures, 1 skipped (13 excluded)
```

## How to Test

```bash
mix compile
mix test test/jido_code_core/agent/schemas_test.exs
```

## Notes/Considerations

- Zoi is included via Jido 2.0 dependency
- Schema fields use `|>` operator to chain modifiers like `Zoi.default/1`
- The `coerce: true` option enables automatic type coercion
- Nested objects can be defined with `Zoi.object(%{...})`
