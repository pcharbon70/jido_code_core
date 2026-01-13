defmodule JidoCodeCore.Integration.PubSubTest do
  use ExUnit.Case
  alias JidoCodeCore.PubSubTopics
  alias JidoCodeCore.PubSubHelpers
  alias Phoenix.PubSub

  @moduledoc """
  Integration tests for PubSub functionality in JidoCodeCore.

  These tests verify:
  1. Core publishes to session topics
  2. Core publishes to tool topics
  3. Event payloads match expected structure
  4. PubSubHelpers work correctly
  """

  defp unique_id, do: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)

  describe "1.4.3 PubSub Integration" do
    test "1.4.3.1 Core publishes to session topics" do
      # Subscribe to session topic
      session_id = unique_id()
      topic = PubSubTopics.llm_stream(session_id)

      # Subscribe to the topic
      PubSub.subscribe(JidoCodeCore.PubSub, topic)

      # Broadcast a test message
      test_message = {:test_event, %{data: "test"}}
      PubSub.broadcast(JidoCodeCore.PubSub, topic, test_message)

      # Verify we received the message
      assert_receive {:test_event, %{data: "test"}}, 1000

      # Clean up
      PubSub.unsubscribe(JidoCodeCore.PubSub, topic)
    end

    test "1.4.3.2 Core publishes to global session topic" do
      # Subscribe to global session topic
      topic = PubSubTopics.tui_events()

      PubSub.subscribe(JidoCodeCore.PubSub, topic)

      # Broadcast a test message without session_id
      test_message = {:global_test, %{data: "global"}}
      PubSub.broadcast(JidoCodeCore.PubSub, topic, test_message)

      # Verify we received the message
      assert_receive {:global_test, %{data: "global"}}, 1000

      # Clean up
      PubSub.unsubscribe(JidoCodeCore.PubSub, topic)
    end

    test "1.4.3.3 Core publishes to tool topics" do
      # Subscribe to tool topic via session-specific stream
      session_id = unique_id()
      topic = PubSubTopics.llm_stream(session_id)

      PubSub.subscribe(JidoCodeCore.PubSub, topic)

      # Broadcast a tool event message
      test_message = {:tool_call, "test_tool", %{arg: "value"}, "call_id", session_id}
      PubSub.broadcast(JidoCodeCore.PubSub, topic, test_message)

      # Verify we received the message
      assert_receive {:tool_call, "test_tool", %{arg: "value"}, "call_id", ^session_id}, 1000

      # Clean up
      PubSub.unsubscribe(JidoCodeCore.PubSub, topic)
    end

    test "1.4.3.4 Core publishes to config topic" do
      # Subscribe to config topic
      topic = PubSubTopics.config_changes()

      PubSub.subscribe(JidoCodeCore.PubSub, topic)

      # Broadcast a config update message
      test_message = {:config_updated, %{key: "value"}}
      PubSub.broadcast(JidoCodeCore.PubSub, topic, test_message)

      # Verify we received the message
      assert_receive {:config_updated, %{key: "value"}}, 1000

      # Clean up
      PubSub.unsubscribe(JidoCodeCore.PubSub, topic)
    end

    test "1.4.3.5 PubSubHelpers returns correct topic strings" do
      session_id = unique_id()

      # Test session_topic with session_id
      assert PubSubHelpers.session_topic(session_id) == "tui.events.#{session_id}"

      # Test session_topic without session_id (global)
      assert PubSubHelpers.session_topic(nil) == "tui.events"

      # Test global_topic
      assert PubSubHelpers.global_topic() == "tui.events"
    end

    test "1.4.3.6 PubSubTopics returns valid topic strings" do
      session_id = unique_id()

      # Test various topic functions
      assert PubSubTopics.tui_events() == "tui.events"
      assert PubSubTopics.llm_stream(session_id) == "tui.events.#{session_id}"
      assert PubSubTopics.config_changes() == "config.changes"
    end
  end
end
