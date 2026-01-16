# Phase 2: Multi-Phase Workflow

This phase implements the full multi-phase workflow: Research, Plan, enhanced Implement, and Verify phases.

## Overview

Phase 2 extends the core loop engine with a complete multi-phase workflow:
- **Research Phase**: Analyze codebase relevant to each task
- **Plan Phase**: Break down tasks into user stories with implementation plans
- **Enhanced Implement Phase**: Process user stories from prd.json
- **Verify Phase**: Run quality checks and verification tests
- **Extended FSM**: Full state machine managing all phase transitions

The workflow follows: `idle` → `researching` → `planning` → `implementing` → `verifying` → `idle`

---

## 2.1 Research Phase Agent

Implement the research phase that analyzes the codebase relevant to a task.

### 2.1.1 Research Module Structure

- [ ] 2.1.1.1 Create `lib/jido_code_core/ralph_loop/phases/research.ex`
- [ ] 2.1.1.2 `use Jido.Agent` with proper configuration
- [ ] 2.1.1.3 Define agent name: "RalphLoop Research Agent"

### 2.1.2 Research Agent State

- [ ] 2.1.2.1 Define state struct:
  ```elixir
  defstruct [
    :task_id,
    :session_id,
    :project_root,
    :findings,
    :files_analyzed
  ]
  ```

### 2.1.3 Research Actions

- [ ] 2.1.3.1 Define `AnalyzeCodebase` action - scan project for relevant files
- [ ] 2.1.3.2 Define `SearchPatterns` action - grep for relevant patterns
- [ ] 2.1.3.3 Define `ReadFiles` action - read relevant file contents
- [ ] 2.1.3.4 Define `CompileFindings` action - create research.md

### 2.1.4 Research Tool Usage

- [ ] 2.1.4.1 Use `glob_search` to find relevant files by extension
- [ ] 2.1.4.2 Use `grep` to search for code patterns
- [ ] 2.1.4.3 Use `read_file` to examine file contents
- [ ] 2.1.4.4 Use `web_search` for external research (optional)

### 2.1.5 Research Output

- [ ] 2.1.5.1 Generate `research.md` with sections:
  - Task Summary
  - Relevant Files Found
  - Code Patterns Discovered
  - Dependencies Identified
  - Potential Issues/Considerations
- [ ] 2.1.5.2 Save via `Storage.write_task_artifact/4`
- [ ] 2.1.5.3 Return `{:ok, research_path}`

### 2.1.6 Research Prompt Template

- [ ] 2.1.6.1 Create `research.md.eex` template:
  ```elixir
  @research_template """
  Research the following task:
  Title: <%= @task.title %>
  Description: <%= @task.description %>

  Steps:
  1. Search for relevant files in the codebase
  2. Identify existing patterns and conventions
  3. Note any dependencies or related code
  4. Document potential issues

  Output findings to research.md
  """
  ```

### 2.1.7 Research Unit Tests

- [ ] 2.1.7.1 Create `test/jido_code_core/ralph_loop/phases/research_test.exs`
- [ ] 2.1.7.2 Test agent initializes with task
- [ ] 2.1.7.3 Test AnalyzeCodebase finds relevant files
- [ ] 2.1.7.4 Test SearchPatterns finds code patterns
- [ ] 2.1.7.5 Test CompileFindings creates research.md
- [ ] 2.1.7.6 Test research.md contains expected sections

---

## 2.2 Plan Phase Agent

Implement the planning phase that creates detailed implementation plans.

### 2.2.1 Plan Module Structure

- [ ] 2.2.1.1 Create `lib/jido_code_core/ralph_loop/phases/plan.ex`
- [ ] 2.2.1.2 `use Jido.Agent` with proper configuration
- [ ] 2.2.1.3 Define agent name: "RalphLoop Plan Agent"

### 2.2.2 Plan Agent State

- [ ] 2.2.2.1 Define state struct:
  ```elixir
  defstruct [
    :task_id,
    :session_id,
    :research_findings,
    :user_stories,
    :dependencies
  ]
  ```

### 2.2.3 Plan Actions

- [ ] 2.2.3.1 Define `AnalyzeRequirements` action - parse task and research
- [ ] 2.2.3.2 Define `BreakdownStories` action - create user stories
- [ ] 2.2.3.3 Define `IdentifyDependencies` action - find required changes
- [ ] 2.2.3.4 Define `CreatePlan` action - generate plan.md
- [ ] 2.2.3.5 Define `CreatePRD` action - generate prd.json

### 2.2.4 Plan Output

- [ ] 2.2.4.1 Generate `plan.md` with sections:
  - Task Overview
  - Implementation Approach
  - User Stories (from prd.json)
  - Files to Modify
  - Testing Strategy
  - Rollback Plan
- [ ] 2.2.4.2 Generate `prd.json` with user stories:
  ```json
  {
    "stories": [
      {
        "id": "story-1",
        "title": "...",
        "description": "...",
        "passes": false
      }
    ]
  }
  ```
- [ ] 2.2.4.3 Save both via storage module

### 2.2.5 Plan Prompt Template

- [ ] 2.2.5.1 Create `plan.md.eex` template with:
  - Task context
  - Research findings inclusion
  - Instructions for breaking down stories
  - Output format requirements

### 2.2.6 Plan Unit Tests

- [ ] 2.2.6.1 Create `test/jido_code_core/ralph_loop/phases/plan_test.exs`
- [ ] 2.2.6.2 Test agent initializes with research
- [ ] 2.2.6.3 Test BreakdownStories creates user stories
- [ ] 2.2.6.4 Test CreatePlan generates plan.md
- [ ] 2.2.6.5 Test CreatePRD generates valid prd.json
- [ ] 2.2.6.6 Test plan includes all required sections

---

## 2.3 Enhanced Implement Phase

Enhance the implement phase to use user stories from prd.json.

### 2.3.1 Story-Based Execution

- [ ] 2.3.1.1 Load prd.json at start of implement phase
- [ ] 2.3.1.2 Iterate through stories in order
- [ ] 2.3.1.3 Track each story's `passes` status
- [ ] 2.3.1.4 Skip stories with `passes: true`

### 2.3.2 Per-Story Processing

- [ ] 2.3.2.1 Implement `process_story/2` - handle single user story
- [ ] 2.3.2.2 Include story title and description in prompt
- [ ] 2.3.2.3 Execute tool calls for story implementation
- [ ] 2.3.2.4 Run tests after story completion
- [ ] 2.3.2.5 Update story status on success/failure

### 2.3.3 Story Commit Strategy

- [ ] 2.3.3.1 Commit after each successful story
- [ ] 2.3.3.2 Include story ID in commit message
- [ ] 2.3.3.3 Format: `[ralph] <task-id>: <story-title>`
- [ ] 2.3.3.4 Append story completion to progress.log

### 2.3.4 Enhanced Implement Tests

- [ ] 2.3.4.1 Test implement loads prd.json
- [ ] 2.3.4.2 Test implement processes stories sequentially
- [ ] 2.3.4.3 Test implement skips completed stories
- [ ] 2.3.4.4 Test implement updates story status
- [ ] 2.3.4.5 Test implement commits per story

---

## 2.4 Verify Phase Agent

Implement the verification phase for quality checks.

### 2.4.1 Verify Module Structure

- [ ] 2.4.1.1 Create `lib/jido_code_core/ralph_loop/phases/verify.ex`
- [ ] 2.4.1.2 `use Jido.Agent` with proper configuration
- [ ] 2.4.1.3 Define agent name: "RalphLoop Verify Agent"

### 2.4.2 Verify Agent State

- [ ] 2.4.2.1 Define state struct:
  ```elixir
  defstruct [
    :task_id,
    :session_id,
    :checks_run,
    :results,
    :final_status
  ]
  ```

### 2.4.3 Verify Actions

- [ ] 2.4.3.1 Define `RunRequiredChecks` action - execute config.required_checks
- [ ] 2.4.3.2 Define `RunFullTestSuite` action - run complete test suite
- [ ] 2.4.3.3 Define `CompileCheck` action - verify code compiles
- [ ] 2.4.3.4 Define `LintCheck` action - run linters (if configured)
- [ ] 2.4.3.5 Define `TypeCheck` action - run type checker (if applicable)
- [ ] 2.4.3.6 Define `SummarizeResults` action - compile verification report

### 2.4.4 Verify Output

- [ ] 2.4.4.1 Generate verification report:
  - Check Name, Status, Duration, Output
  - Overall Pass/Fail status
  - Recommendations for failures
- [ ] 2.4.4.2 Append to task's progress.log
- [ ] 2.4.4.3 Return `:pass` or `:fail` status

### 2.4.5 Verify Prompt Template

- [ ] 2.4.5.1 Create `verify.md.eex` template with:
  - Instructions for running checks
  - Error analysis guidance
  - Fix suggestions for failures

### 2.4.6 Verify Unit Tests

- [ ] 2.4.6.1 Create `test/jido_code_core/ralph_loop/phases/verify_test.exs`
- [ ] 2.4.6.2 Test RunRequiredChecks executes commands
- [ ] 2.4.6.3 Test RunFullTestSuite runs tests
- [ ] 2.4.6.4 Test CompileCheck detects compilation errors
- [ ] 2.4.6.5 Test SummarizeResults creates report
- [ ] 2.4.6.6 Test verify returns correct pass/fail status

---

## 2.5 Orchestrator FSM Enhancement

Update orchestrator for full multi-phase workflow.

### 2.5.1 Extended FSM States

- [ ] 2.5.1.1 Add `:researching` state
- [ ] 2.5.1.2 Add `:planning` state
- [ ] 2.5.1.3 Update transition sequence:
  - `:idle` → `:researching` → `:planning` → `:implementing` → `:verifying` → `:idle`

### 2.5.2 Phase Coordination

- [ ] 2.5.2.1 Implement research phase trigger
- [ ] 2.5.2.2 Pass research findings to plan phase
- [ ] 2.5.2.3 Pass plan output to implement phase
- [ ] 2.5.2.4 Pass implement results to verify phase

### 2.5.3 Phase Failure Handling

- [ ] 2.5.3.1 Define behavior when research fails
- [ ] 2.5.3.2 Define behavior when plan fails
- [ ] 2.5.3.3 Define retry logic for failed phases
- [ ] 2.5.3.4 Define max retry limit per phase

### 2.5.4 Enhanced Orchestrator Tests

- [ ] 2.5.4.1 Test full phase sequence
- [ ] 2.5.4.2 Test phase failure handling
- [ ] 2.5.4.3 Test phase retry logic
- [ ] 2.5.4.4 Test data passing between phases

---

## 2.6 Phase 2 Integration Tests

End-to-end tests for multi-phase workflow.

### 2.6.1 Complete Workflow Test

- [ ] 2.6.1.1 Test: Research → Plan → Implement → Verify flow
- [ ] 2.6.1.2 Test: All artifacts created correctly
- [ ] 2.6.1.3 Test: Task status transitions through all phases
- [ ] 2.6.1.4 Test: Loop completes successfully

### 2.6.2 Failure Scenario Tests

- [ ] 2.6.2.1 Test: Loop continues after single task failure
- [ ] 2.6.2.2 Test: Loop stops after verification failure
- [ ] 2.6.2.3 Test: Recovery after interrupted loop

---

## Phase 2 Success Criteria

| Criterion | Status |
|-----------|--------|
| **Research**: Codebase analysis working | Pending |
| **Plan**: User story generation working | Pending |
| **Implement**: Story-based execution | Pending |
| **Verify**: Quality checks complete | Pending |
| **Orchestrator**: Full FSM transitions | Pending |
| **Tests**: Multi-phase integration tested | Pending |

---

## Phase 2 Critical Files

**New Files:**
- `lib/jido_code_core/ralph_loop/phases/research.ex`
- `lib/jido_code_core/ralph_loop/phases/plan.ex`
- `lib/jido_code_core/ralph_loop/phases/verify.ex`
- `test/jido_code_core/ralph_loop/phases/research_test.exs`
- `test/jido_code_core/ralph_loop/phases/plan_test.exs`
- `test/jido_code_core/ralph_loop/phases/verify_test.exs`

**Modified Files:**
- `lib/jido_code_core/ralph_loop/phases/implement.ex` - Enhance for stories
- `lib/jido_code_core/ralph_loop/orchestrator.ex` - Extended FSM
