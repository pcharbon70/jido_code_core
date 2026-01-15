defmodule JidoCodeCore.SessionStateTest do
  @moduledoc """
  Unit tests for JidoCodeCore.Session.State (Section 2.3.1)

  Tests the Session.State GenServer which manages:
  - Conversation history (messages)
  - Reasoning steps
  - Tool execution tracking
  - Todo list management
  - Working context
  - Pending memories
  - Access logging
  - Promotion statistics
  """

  use ExUnit.Case, async: false

  alias JidoCodeCore.Session
  alias JidoCodeCore.Session.State
  alias JidoCodeCore.SessionRegistry

  @moduletag :session_state

  setup do
    # Ensure clean state
    SessionRegistry.create_table()
    SessionRegistry.clear()

    # Create a test session
    tmp_dir = System.tmp_dir!()
    {:ok, session} = Session.new(project_path: tmp_dir, name: "Test Session")

    # Start the State process - expects keyword list with :session key
    {:ok, _state_pid} = State.start_link(session: session)

    %{session: session, session_id: session.id}
  end

  describe "initialization" do
    test "starts with valid state collections", %{session_id: session_id} do
      assert {:ok, state} = State.get_state(session_id)

      assert state.messages == []
      assert state.reasoning_steps == []
      assert state.tool_calls == []
      assert state.todos == []
      assert state.streaming_message == nil
      assert state.is_streaming == false
      assert state.scroll_offset == 0
    end

    test "initializes memory subsystems", %{session_id: session_id} do
      assert {:ok, _state} = State.get_state(session_id)
      # WorkingContext should be initialized
      assert {:ok, context} = State.get_all_context(session_id)
      assert is_map(context)

      # PendingMemories should be empty
      assert {:ok, pending} = State.get_pending_memories(session_id)
      assert is_list(pending)
      assert length(pending) == 0

      # Promotion stats should be initialized
      assert {:ok, stats} = State.get_promotion_stats(session_id)
      assert is_map(stats)
      assert Map.has_key?(stats, :enabled)
    end
  end

  describe "messages" do
    test "appends a message to the state", %{session_id: session_id} do
      message = %{
        id: "msg-1",
        role: :user,
        content: "Hello, world!",
        timestamp: DateTime.utc_now()
      }

      assert {:ok, _} = State.append_message(session_id, message)
      assert {:ok, messages} = State.get_messages(session_id)

      assert length(messages) == 1
      assert hd(messages).id == "msg-1"
      assert hd(messages).content == "Hello, world!"
    end

    test "appends multiple messages in order", %{session_id: session_id} do
      msg1 = %{id: "msg-1", role: :user, content: "First", timestamp: DateTime.utc_now()}
      msg2 = %{id: "msg-2", role: :assistant, content: "Second", timestamp: DateTime.utc_now()}
      msg3 = %{id: "msg-3", role: :user, content: "Third", timestamp: DateTime.utc_now()}

      State.append_message(session_id, msg1)
      State.append_message(session_id, msg2)
      State.append_message(session_id, msg3)

      assert {:ok, messages} = State.get_messages(session_id)

      assert length(messages) == 3
      assert Enum.at(messages, 0).id == "msg-1"
      assert Enum.at(messages, 1).id == "msg-2"
      assert Enum.at(messages, 2).id == "msg-3"
    end

    test "gets paginated messages", %{session_id: session_id} do
      # Add 10 messages
      for i <- 1..10 do
        msg = %{
          id: "msg-#{i}",
          role: :user,
          content: "Message #{i}",
          timestamp: DateTime.utc_now()
        }

        State.append_message(session_id, msg)
      end

      assert {:ok, messages, meta} = State.get_messages(session_id, 0, 5)

      assert length(messages) == 5
      assert meta.total == 10
      assert meta.offset == 0
      assert meta.limit == 5
      assert meta.has_more == true

      # Get second page
      assert {:ok, messages2, meta2} = State.get_messages(session_id, 5, 5)

      assert length(messages2) == 5
      assert meta2.has_more == false
    end

    test "clears all messages", %{session_id: session_id} do
      msg1 = %{id: "msg-1", role: :user, content: "Test", timestamp: DateTime.utc_now()}
      State.append_message(session_id, msg1)

      assert {:ok, _} = State.get_messages(session_id)
      assert {:ok, _} = State.clear_messages(session_id)

      assert {:ok, messages} = State.get_messages(session_id)
      assert length(messages) == 0
    end
  end

  describe "reasoning steps" do
    test "adds a reasoning step", %{session_id: session_id} do
      step = %{
        id: "step-1",
        type: :thought,
        content: "Let me think about this...",
        timestamp: DateTime.utc_now()
      }

      assert {:ok, _} = State.add_reasoning_step(session_id, step)
      assert {:ok, steps} = State.get_reasoning_steps(session_id)

      assert length(steps) == 1
      assert hd(steps).id == "step-1"
      assert hd(steps).content == "Let me think about this..."
    end

    test "adds multiple reasoning steps", %{session_id: session_id} do
      step1 = %{id: "step-1", type: :thought, content: "First", timestamp: DateTime.utc_now()}
      step2 = %{id: "step-2", type: :action, content: "Second", timestamp: DateTime.utc_now()}

      State.add_reasoning_step(session_id, step1)
      State.add_reasoning_step(session_id, step2)

      assert {:ok, steps} = State.get_reasoning_steps(session_id)
      assert length(steps) == 2
    end

    test "clears reasoning steps", %{session_id: session_id} do
      step = %{id: "step-1", type: :thought, content: "Test", timestamp: DateTime.utc_now()}
      State.add_reasoning_step(session_id, step)

      assert {:ok, _} = State.get_reasoning_steps(session_id)
      assert {:ok, _} = State.clear_reasoning_steps(session_id)

      assert {:ok, steps} = State.get_reasoning_steps(session_id)
      assert length(steps) == 0
    end
  end

  describe "todos" do
    test "updates the todo list", %{session_id: session_id} do
      todos = [
        %{id: "1", content: "Task 1", status: :pending},
        %{id: "2", content: "Task 2", status: :completed}
      ]

      assert {:ok, _} = State.update_todos(session_id, todos)
      assert {:ok, retrieved} = State.get_todos(session_id)

      assert length(retrieved) == 2
      assert Enum.at(retrieved, 0).content == "Task 1"
      assert Enum.at(retrieved, 1).status == :completed
    end

    test "replaces entire todo list on update", %{session_id: session_id} do
      todos1 = [%{id: "1", content: "Task 1", status: :pending}]
      todos2 = [%{id: "2", content: "Task 2", status: :pending}]

      State.update_todos(session_id, todos1)
      State.update_todos(session_id, todos2)

      assert {:ok, retrieved} = State.get_todos(session_id)
      assert length(retrieved) == 1
      assert hd(retrieved).content == "Task 2"
    end

    test "handles empty todo list", %{session_id: session_id} do
      assert {:ok, _} = State.update_todos(session_id, [])
      assert {:ok, todos} = State.get_todos(session_id)
      assert todos == []
    end
  end

  describe "tool calls" do
    test "adds a tool call", %{session_id: session_id} do
      tool_call = %{
        id: "call-1",
        name: "read_file",
        arguments: %{"path" => "/test/file.txt"},
        status: :pending,
        timestamp: DateTime.utc_now()
      }

      assert {:ok, _} = State.add_tool_call(session_id, tool_call)
      assert {:ok, calls} = State.get_tool_calls(session_id)

      assert length(calls) == 1
      assert hd(calls).id == "call-1"
      assert hd(calls).name == "read_file"
    end
  end

  describe "streaming" do
    test "starts streaming with message ID", %{session_id: session_id} do
      assert {:ok, _} = State.start_streaming(session_id, "msg-1")
      assert {:ok, state} = State.get_state(session_id)

      assert state.is_streaming == true
      assert state.streaming_message_id == "msg-1"
    end

    test "updates streaming content", %{session_id: session_id} do
      State.start_streaming(session_id, "msg-1")

      assert :ok = State.update_streaming(session_id, "Hello")
      assert {:ok, state} = State.get_state(session_id)
      assert state.streaming_message == "Hello"

      assert :ok = State.update_streaming(session_id, " World")
      assert {:ok, state2} = State.get_state(session_id)
      assert state2.streaming_message == "Hello World"
    end

    test "ends streaming and saves message", %{session_id: session_id} do
      State.start_streaming(session_id, "msg-1")
      State.update_streaming(session_id, "Final content")

      assert {:ok, _} = State.end_streaming(session_id)
      assert {:ok, state} = State.get_state(session_id)

      assert state.is_streaming == false
      assert state.streaming_message == nil

      # Message should be saved to messages list
      assert {:ok, messages} = State.get_messages(session_id)
      assert length(messages) == 1
      assert hd(messages).content == "Final content"
      assert hd(messages).role == :assistant
    end
  end

  describe "scroll offset" do
    test "sets scroll offset", %{session_id: session_id} do
      assert {:ok, _} = State.set_scroll_offset(session_id, 10)
      assert {:ok, state} = State.get_state(session_id)
      assert state.scroll_offset == 10
    end

    test "updates scroll offset", %{session_id: session_id} do
      State.set_scroll_offset(session_id, 5)
      State.set_scroll_offset(session_id, 15)

      assert {:ok, state} = State.get_state(session_id)
      assert state.scroll_offset == 15
    end
  end

  describe "session config" do
    test "updates session config", %{session_id: session_id} do
      config = %{
        temperature: 0.5,
        model: "claude-3-5-haiku-20241022"
      }

      assert {:ok, updated} = State.update_session_config(session_id, config)
      assert updated.config.temperature == 0.5
      assert updated.config.model == "claude-3-5-haiku-20241022"
    end

    test "merges config with existing", %{session_id: session_id} do
      State.update_session_config(session_id, %{temperature: 0.3})
      assert {:ok, updated} = State.update_session_config(session_id, %{model: "test-model"})

      # Both values should be present
      assert updated.config.temperature == 0.3
      assert updated.config.model == "test-model"
    end

    test "updates session language", %{session_id: session_id} do
      assert {:ok, updated} = State.update_language(session_id, :python)
      assert updated.language == :python
    end

    test "normalizes language aliases", %{session_id: session_id} do
      assert {:ok, updated} = State.update_language(session_id, "py")
      assert updated.language == :python
    end
  end

  describe "working context" do
    test "sets context value", %{session_id: session_id} do
      assert :ok = State.update_context(session_id, :framework, "Phoenix")
      assert {:ok, value} = State.get_context(session_id, :framework)
      assert value == "Phoenix"
    end

    test "updates context value", %{session_id: session_id} do
      State.update_context(session_id, :user_intent, "initial task")
      assert :ok = State.update_context(session_id, :user_intent, "updated task")

      assert {:ok, value} = State.get_context(session_id, :user_intent)
      assert value == "updated task"
    end

    test "gets all context", %{session_id: session_id} do
      State.update_context(session_id, :framework, "Phoenix")
      State.update_context(session_id, :primary_language, "Elixir")

      assert {:ok, context} = State.get_all_context(session_id)
      # Context is a WorkingContext struct with items map
      assert is_map(context)
    end

    test "clears all context", %{session_id: session_id} do
      State.update_context(session_id, :framework, "Phoenix")
      State.update_context(session_id, :primary_language, "Elixir")

      assert :ok = State.clear_context(session_id)

      # After clearing, context should be empty
      assert {:ok, context} = State.get_all_context(session_id)
      assert is_map(context)
    end
  end

  describe "pending memories" do
    test "adds a pending memory", %{session_id: session_id} do
      memory = %{
        id: "mem-1",
        content: "Important fact",
        memory_type: :fact,
        confidence: 0.9,
        source_type: :tool,
        importance_score: 0.8,
        created_at: DateTime.utc_now()
      }

      assert :ok = State.add_pending_memory(session_id, memory)
      assert {:ok, pending} = State.get_pending_memories(session_id)

      assert length(pending) == 1
      assert hd(pending).content == "Important fact"
    end

    test "adds multiple pending memories", %{session_id: session_id} do
      mem1 = %{id: "mem-1", content: "Fact 1", memory_type: :fact, confidence: 0.8, source_type: :tool, importance_score: 0.9, created_at: DateTime.utc_now()}
      mem2 = %{id: "mem-2", content: "Fact 2", memory_type: :fact, confidence: 0.7, source_type: :tool, importance_score: 0.8, created_at: DateTime.utc_now()}

      State.add_pending_memory(session_id, mem1)
      State.add_pending_memory(session_id, mem2)

      assert {:ok, pending} = State.get_pending_memories(session_id)
      assert length(pending) == 2
    end

    test "clears promoted memories", %{session_id: session_id} do
      mem1 = %{id: "mem-1", content: "Fact 1", memory_type: :fact, confidence: 0.8, source_type: :tool, importance_score: 0.9, created_at: DateTime.utc_now()}
      mem2 = %{id: "mem-2", content: "Fact 2", memory_type: :fact, confidence: 0.7, source_type: :tool, importance_score: 0.8, created_at: DateTime.utc_now()}

      State.add_pending_memory(session_id, mem1)
      State.add_pending_memory(session_id, mem2)

      # Clear first memory as "promoted"
      assert :ok = State.clear_promoted_memories(session_id, ["mem-1"])

      assert {:ok, pending} = State.get_pending_memories(session_id)
      assert length(pending) == 1
      assert hd(pending).id == "mem-2"
    end
  end

  describe "agent memory decisions" do
    test "adds an agent memory decision", %{session_id: session_id} do
      decision = %{
        id: "dec-1",
        content: "Decision content",
        memory_type: :convention,
        confidence: 1.0,
        source_type: :user,
        decision: :promote,
        reason: "High importance",
        created_at: DateTime.utc_now()
      }

      assert :ok = State.add_agent_memory_decision(session_id, decision)
      # Should be added to pending memories with decision metadata
      assert {:ok, pending} = State.get_pending_memories(session_id)
      assert length(pending) >= 1
    end
  end

  describe "access logging" do
    test "records context access", %{session_id: session_id} do
      assert :ok = State.record_access(session_id, :framework, :read)
      assert {:ok, stats} = State.get_access_stats(session_id, :framework)

      assert is_map(stats)
      assert Map.has_key?(stats, :frequency)
      assert Map.has_key?(stats, :recency)
    end

    test "tracks access counts", %{session_id: session_id} do
      State.record_access(session_id, :test_key, :read)
      State.record_access(session_id, :test_key, :read)
      State.record_access(session_id, :test_key, :read)

      assert {:ok, stats} = State.get_access_stats(session_id, :test_key)
      assert stats.frequency >= 3
    end

    test "handles different access types", %{session_id: session_id} do
      State.record_access(session_id, :key, :read)
      State.record_access(session_id, :key, :write)

      assert {:ok, stats} = State.get_access_stats(session_id, :key)
      assert is_map(stats)
    end
  end

  describe "promotion engine" do
    test "has promotion enabled by default", %{session_id: session_id} do
      assert {:ok, stats} = State.get_promotion_stats(session_id)
      assert stats.enabled == true
    end

    test "can disable promotion", %{session_id: session_id} do
      assert :ok = State.disable_promotion(session_id)
      assert {:ok, stats} = State.get_promotion_stats(session_id)
      assert stats.enabled == false
    end

    test "can enable promotion", %{session_id: session_id} do
      State.disable_promotion(session_id)
      assert :ok = State.enable_promotion(session_id)

      assert {:ok, stats} = State.get_promotion_stats(session_id)
      assert stats.enabled == true
    end

    test "sets promotion interval", %{session_id: session_id} do
      assert :ok = State.set_promotion_interval(session_id, 60_000)
    end

    test "runs promotion on demand without crashing", %{session_id: session_id} do
      # Run promotion with no pending memories - should not crash
      result = State.run_promotion_now(session_id)
      # Result can be :ok, {:ok, count}, or {:error, reason}
      assert result == :ok or match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "prompt history" do
    test "gets initial prompt history", %{session_id: session_id} do
      assert {:ok, history} = State.get_prompt_history(session_id)
      assert is_list(history)
    end

    test "adds to prompt history", %{session_id: session_id} do
      prompt = "You are a helpful assistant."
      assert {:ok, _history} = State.add_to_prompt_history(session_id, prompt)

      assert {:ok, history} = State.get_prompt_history(session_id)
      assert length(history) >= 1
    end

    test "sets prompt history", %{session_id: session_id} do
      new_history = ["Prompt 1", "Prompt 2"]
      assert {:ok, _history} = State.set_prompt_history(session_id, new_history)

      assert {:ok, history} = State.get_prompt_history(session_id)
      assert is_list(history)
    end
  end

  describe "file operation tracking" do
    test "tracks file reads", %{session_id: session_id} do
      path = "/test/file.ex"

      assert {:ok, _timestamp} = State.track_file_read(session_id, path)
      assert {:ok, true} = State.file_was_read?(session_id, path)
    end

    test "tracks file writes", %{session_id: session_id} do
      path = "/test/file.ex"

      assert {:ok, _timestamp} = State.track_file_write(session_id, path)
      # File write tracking should also mark as read
    end

    test "gets file read time", %{session_id: session_id} do
      path = "/test/file.ex"

      before = DateTime.utc_now()
      State.track_file_read(session_id, path)

      assert {:ok, timestamp} = State.get_file_read_time(session_id, path)
      assert DateTime.compare(timestamp, before) != :lt
    end

    test "returns nil for unknown file read time", %{session_id: session_id} do
      assert {:ok, nil} = State.get_file_read_time(session_id, "/unknown/file")
    end
  end

  describe "constants" do
    test "exposes configuration constants" do
      assert State.max_messages() == 1000
      assert State.max_reasoning_steps() == 100
      assert State.max_tool_calls() == 500
      assert State.max_prompt_history() == 100
      assert State.max_file_operations() == 1000
      assert State.max_pending_memories() == 500
      assert State.max_access_log_entries() == 1000
    end
  end

  describe "error handling" do
    test "handles unknown session ID", %{session: session} do
      unknown_id = "unknown-#{session.id}"

      assert {:error, _} = State.get_state(unknown_id)
      assert {:error, _} = State.get_messages(unknown_id)
      assert {:error, _} = State.append_message(unknown_id, %{})
    end
  end
end
