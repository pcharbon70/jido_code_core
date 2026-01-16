# Phase 3: Advanced Features

This phase implements advanced features: memory integration, error handling, recovery, and auto-PR creation.

## Overview

Phase 3 adds sophisticated capabilities to the Ralph Loop:
- **Memory Integration**: Connect with JidoCodeCore's short-term and long-term memory systems
- **Error Handling**: Classify errors and implement retry logic with exponential backoff
- **Recovery Mechanisms**: Resume from checkpoints, detect incomplete operations
- **Auto-PR Creation**: Automatically create pull requests upon successful completion
- **Doctor Command**: Diagnostics and repair utilities for state management

---

## 3.1 Memory System Integration

Integrate Ralph Loop with JidoCodeCore's memory systems.

### 3.1.1 Short-Term Memory Integration

- [ ] 3.1.1.1 Store loop context in working memory
- [ ] 3.1.1.2 Track current task in memory
- [ ] 3.1.1.3 Log phase transitions to access log
- [ ] 3.1.1.4 Store pending memories during execution

### 3.1.2 Long-Term Memory Integration

- [ ] 3.1.2.1 Promote loop learnings to long-term memory
- [ ] 3.1.2.2 Store codebase patterns discovered during research
- [ ] 3.1.2.3 Store successful approaches for reuse
- [ ] 3.1.2.4 Store failures as anti-patterns

### 3.1.3 Memory Queries

- [ ] 3.1.3.1 Query long-term memory before research phase
- [ ] 3.1.3.2 Use prior learnings to accelerate research
- [ ] 3.1.3.3 Query for similar past tasks
- [ ] 3.1.3.4 Include relevant memories in prompts

### 3.1.4 Memory Tests

- [ ] 3.1.4.1 Test loop stores context in short-term memory
- [ ] 3.1.4.2 Test loop promotes learnings to long-term
- [ ] 3.1.4.3 Test loop queries prior learnings
- [ ] 3.1.4.4 Test memories persist across loop runs

---

## 3.2 Error Handling and Recovery

Implement robust error handling and recovery mechanisms.

### 3.2.1 Error Classification

- [ ] 3.2.1.1 Define error categories:
  - `:transient` - temporary failures (rate limits, network)
  - `:recoverable` - fixable errors (test failures)
  - `:fatal` - unrecoverable errors
- [ ] 3.2.1.2 Create `classify_error/1` function

### 3.2.2 Retry Logic

- [ ] 3.2.2.1 Implement exponential backoff for transient errors
- [ ] 3.2.2.2 Define max retries per phase
- [ ] 3.2.2.3 Track retry count in LoopState
- [ ] 3.2.2.4 Stop after max retries exceeded

### 3.2.3 Recovery Mechanisms

- [ ] 3.2.3.1 Implement resume from checkpoint
- [ ] 3.2.3.2 Detect incomplete operations on restart
- [ ] 3.2.3.3 Rollback failed commits if needed
- [ ] 3.2.3.4 Clean up partial state

### 3.2.4 Error Logging

- [ ] 3.2.4.1 Log all errors to progress.log
- [ ] 3.2.4.2 Include stack traces for debugging
- [ ] 3.2.4.3 Store error context in memory
- [ ] 3.2.4.4 Emit PubSub error events

### 3.2.5 Error Handling Tests

- [ ] 3.2.5.1 Test transient errors trigger retry
- [ ] 3.2.5.2 Test fatal errors stop loop
- [ ] 3.2.5.3 Test recovery from checkpoint
- [ ] 3.2.5.4 Test error logging works correctly

---

## 3.3 Auto-PR Creation

Implement automatic pull request creation upon successful completion.

### 3.3.1 PR Creation Module

- [ ] 3.3.1.1 Create `lib/jido_code_core/ralph_loop/pr_creator.ex`
- [ ] 3.3.1.2 Define PR creator struct

### 3.3.2 Git Operations for PR

- [ ] 3.3.2.1 Push branch to remote
- [ ] 3.3.2.2 Detect GitHub vs GitLab vs other
- [ ] 3.3.2.3 Create PR via API or CLI

### 3.3.3 PR Content Generation

- [ ] 3.3.3.1 Generate PR title from task titles
- [ ] 3.3.3.2 Generate PR body from:
  - Task list with descriptions
  - Links to research/plans
  - Test results summary
  - Verification report
- [ ] 3.3.3.3 Add labels based on task types

### 3.3.4 PR Creation Tests

- [ ] 3.3.4.1 Test branch pushes to remote
- [ ] 3.3.4.2 Test PR creates on GitHub
- [ ] 3.3.4.3 Test PR content is formatted correctly
- [ ] 3.3.4.4 Test skip when auto_pr is false

---

## 3.4 Doctor Command

Implement state repair and diagnostics.

### 3.4.1 Doctor Module

- [ ] 3.4.1.1 Create `lib/jido_code_core/ralph_loop/doctor.ex`
- [ ] 3.4.1.2 Define diagnostic checks

### 3.4.2 Diagnostic Checks

- [ ] 3.4.2.1 Check directory structure integrity
- [ ] 3.4.2.2 Check JSON file validity
- [ ] 3.4.2.3 Check task state consistency
- [ ] 3.4.2.4 Check for orphaned artifacts
- [ ] 3.4.2.5 Check git state (uncommitted changes)

### 3.4.3 Repair Actions

- [ ] 3.4.3.1 Fix invalid JSON files
- [ ] 3.4.3.2 Clean orphaned artifacts
- [ ] 3.4.3.3 Reset stuck tasks to pending
- [ ] 3.4.3.4 Archive old loop runs

### 3.4.4 Doctor API

- [ ] 3.4.4.1 Add `doctor/1` to API.RalphLoop
- [ ] 3.4.4.2 Add `repair/2` to API.RalphLoop
- [ ] 3.4.4.3 Return diagnostic report

### 3.4.5 Doctor Tests

- [ ] 3.4.5.1 Test doctor detects issues
- [ ] 3.4.5.2 Test repair fixes issues
- [ ] 3.4.5.3 Test archive removes old runs

---

## Phase 3 Success Criteria

| Criterion | Status |
|-----------|--------|
| **Memory**: Integration working | Pending |
| **Errors**: Classified and handled | Pending |
| **Recovery**: Resume from checkpoint | Pending |
| **Auto-PR**: Creates PRs | Pending |
| **Doctor**: Diagnostics and repair | Pending |

---

## Phase 3 Critical Files

**New Files:**
- `lib/jido_code_core/ralph_loop/pr_creator.ex`
- `lib/jido_code_core/ralph_loop/doctor.ex`
- `test/jido_code_core/ralph_loop/pr_creator_test.exs`
- `test/jido_code_core/ralph_loop/doctor_test.exs`

**Modified Files:**
- `lib/jido_code_core/ralph_loop/manager.ex` - Add error handling
- `lib/jido_code_core/ralph_loop/orchestrator.ex` - Add recovery
