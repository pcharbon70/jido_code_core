# Phase 4: TUI Integration

This phase implements TUI commands and progress visualization for the JidoCode TUI application.

## Overview

Phase 4 provides the user interface for Ralph Loop in the JidoCode TUI:
- **TUI Commands**: `/ralph` slash commands for loop management
- **Progress Visualization**: Real-time display of loop status and activity
- **Configuration Editor**: In-TUI config editing
- **Keyboard Shortcuts**: Quick access to common operations
- **PubSub Integration**: Event-driven updates for UI responsiveness

---

## 4.1 TUI Commands

Implement slash commands for Ralph Loop management in the TUI.

### 4.1.1 Command Registration

- [ ] 4.1.1.1 Register `/ralph` command group in TUI
- [ ] 4.1.1.2 Register subcommands: init, start, stop, pause, resume, status, log, config

### 4.1.2 /ralph init Command

- [ ] 4.1.2.1 Create `.jido_code/ralph/` directory
- [ ] 4.1.2.2 Create default `config.json`
- [ ] 4.1.2.3 Create empty `tasks.json`
- [ ] 4.1.2.4 Create prompt templates
- [ ] 4.1.2.5 Display success message

### 4.1.3 /ralph add Command

- [ ] 4.1.3.1 Parse task title and description
- [ ] 4.1.3.2 Create new task with UUID
- [ ] 4.1.3.3 Append to tasks.json
- [ ] 4.1.3.4 Display task ID and confirmation

### 4.1.4 /ralph start Command

- [ ] 4.1.4.1 Call `API.RalphLoop.start_loop/2`
- [ ] 4.1.4.2 Display loop ID
- [ ] 4.1.4.3 Switch to progress view
- [ ] 4.1.4.4 Handle errors gracefully

### 4.1.5 /ralph stop Command

- [ ] 4.1.5.1 Call `API.RalphLoop.stop_loop/1`
- [ ] 4.1.5.2 Confirm shutdown with user
- [ ] 4.1.5.3 Display final status

### 4.1.6 /ralph pause Command

- [ ] 4.1.6.1 Call `API.RalphLoop.pause_loop/1`
- [ ] 4.1.6.2 Display paused status

### 4.1.7 /ralph resume Command

- [ ] 4.1.7.1 Call `API.RalphLoop.resume_loop/1`
- [ ] 4.1.7.2 Display resumed status

### 4.1.8 /ralph status Command

- [ ] 4.1.8.1 Call `API.RalphLoop.get_loop_status/1`
- [ ] 4.1.8.2 Display formatted status:
  - Loop ID
  - Current status
  - Current task/phase
  - Iteration count
  - Tasks completed/remaining

### 4.1.9 /ralph log Command

- [ ] 4.1.9.1 Accept optional task ID
- [ ] 4.1.9.2 Read progress.log for task
- [ ] 4.1.9.3 Display in scrollable view
- [ ] 4.1.9.4 Handle missing task ID

### 4.1.10 /ralph config Command

- [ ] 4.1.10.1 Display current config
- [ ] 4.1.10.2 Support `--edit` flag to open editor
- [ ] 4.1.10.3 Validate config on save

---

## 4.2 Progress Visualization

Implement real-time progress display in the TUI.

### 4.2.1 Progress View Component

- [ ] 4.2.1.1 Create progress view module in TUI
- [ ] 4.2.1.2 Subscribe to PubSub events for loop updates
- [ ] 4.2.1.3 Render loop status in real-time

### 4.2.2 Display Elements

- [ ] 4.2.2.1 Status indicator (running/paused/error/completed)
- [ ] 4.2.2.2 Current task display
- [ ] 4.2.2.3 Current phase display with progress
- [ ] 4.2.2.4 Task list with status badges
- [ ] 4.2.2.5 Iteration counter
- [ ] 4.2.2.6 Recent activity log

### 4.2.3 Task List View

- [ ] 4.2.3.1 Show all tasks in table format
- [ ] 4.2.3.2 Color-coded status indicators
- [ ] 4.2.3.3 Sort by priority or status
- [ ] 4.2.3.4 Scroll for large lists

### 4.2.4 Phase Progress Display

- [ ] 4.2.4.1 Show phase sequence with current highlighted
- [ ] 4.2.4.2 Show progress bar for current phase
- [ ] 4.2.4.3 Show user stories for implement phase
- [ ] 4.2.4.4 Show verification check results

### 4.2.5 Streaming Output

- [ ] 4.2.5.1 Display LLM thoughts during phases
- [ ] 4.2.5.2 Display tool execution results
- [ ] 4.2.5.3 Auto-scroll to latest output
- [ ] 4.2.5.4 Support pause/resume of scrolling

---

## 4.3 Configuration Editor

Implement TUI-based configuration editor.

### 4.3.1 Config Editor View

- [ ] 4.3.1.1 Create config editor view
- [ ] 4.3.1.2 Load current config into form
- [ ] 4.3.1.3 Support field editing

### 4.3.2 Field Editors

- [ ] 4.3.2.1 Text input for strings
- [ ] 4.3.2.2 Number input for integers
- [ ] 4.3.2.3 Toggle for booleans
- [ ] 4.3.2.4 List editor for required_checks

### 4.3.3 Validation Display

- [ ] 4.3.3.1 Show validation errors inline
- [ ] 4.3.3.2 Highlight invalid fields
- [ ] 4.3.3.3 Prevent save with errors

### 4.3.4 Save/Cancel

- [ ] 4.3.4.1 Save writes to config.json
- [ ] 4.3.4.2 Cancel discards changes
- [ ] 4.3.4.3 Confirm before overwriting

---

## 4.4 Keyboard Shortcuts

Add keyboard shortcuts for Ralph Loop operations.

### 4.4.1 Global Shortcuts

- [ ] 4.4.1.1 `Ctrl+R` - Open Ralph Loop menu
- [ ] 4.4.1.2 `Ctrl+Shift+S` - Status view
- [ ] 4.4.1.3 `Ctrl+Shift+P` - Pause/resume

### 4.4.2 Progress View Shortcuts

- [ ] 4.4.2.1 `q` - Close progress view
- [ ] 4.4.2.2 `s` - Show status
- [ ] 4.4.2.3 `l` - Show log
- [ ] 4.4.2.4 `c` - Show config
- [ ] 4.4.2.5 Space` - Pause/resume

---

## 4.5 PubSub Integration

Integrate with existing PubSub system for real-time updates.

### 4.5.1 Event Definitions

- [ ] 4.5.1.1 Define `:ralph_loop_started` event
- [ ] 4.5.1.2 Define `:ralph_loop_stopped` event
- [ ] 4.5.1.3 Define `:ralph_task_started` event
- [ ] 4.5.1.4 Define `:ralph_task_completed` event
- [ ] 4.5.1.5 Define `:ralph_phase_changed` event
- [ ] 4.5.1.6 Define `:ralph_error` event

### 4.5.2 Event Publishing

- [ ] 4.5.2.1 Manager publishes events on state changes
- [ ] 4.5.2.2 Orchestrator publishes phase events
- [ ] 4.5.2.3 Phase agents publish progress events

### 4.5.3 Event Subscriptions

- [ ] 4.5.3.1 TUI subscribes to loop topic
- [ ] 4.5.3.2 Progress view updates on events
- [ ] 4.5.3.3 Status bar shows current state

---

## Phase 4 Success Criteria

| Criterion | Status |
|-----------|--------|
| **Commands**: All /ralph commands working | Pending |
| **Progress**: Real-time visualization | Pending |
| **Config**: TUI editor functional | Pending |
| **Shortcuts**: Keyboard navigation | Pending |
| **PubSub**: Event integration | Pending |

---

## Phase 4 Critical Files

**New Files:**
- `lib/jido_code/tui/commands/ralph.ex`
- `lib/jido_code/tui/views/ralph_progress.ex`
- `lib/jido_code/tui/views/ralph_config.ex`
- `lib/jido_code/tui/views/ralph_log.ex`

**Modified Files:**
- `lib/jido_code/tui/state.ex` - Add Ralph Loop state
- `lib/jido_code/tui/model.ex` - Add Ralph Loop handlers
- `lib/jido_code_core/ralph_loop/manager.ex` - Add PubSub events
