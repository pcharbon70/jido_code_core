defmodule JidoCodeCore.Memory.ShortTerm.WorkingContextTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Memory.ShortTerm.WorkingContext
  alias JidoCodeCore.Memory.Types

  doctest WorkingContext

  describe "new/0" do
    test "creates empty context with default max_tokens" do
      ctx = WorkingContext.new()

      assert ctx.items == %{}
      assert ctx.current_tokens == 0
      assert ctx.max_tokens == 12_000
    end
  end

  describe "new/1" do
    test "creates empty context with custom max_tokens" do
      ctx = WorkingContext.new(8_000)

      assert ctx.items == %{}
      assert ctx.current_tokens == 0
      assert ctx.max_tokens == 8_000
    end

    test "rejects non-positive max_tokens" do
      assert_raise FunctionClauseError, fn ->
        WorkingContext.new(0)
      end

      assert_raise FunctionClauseError, fn ->
        WorkingContext.new(-100)
      end
    end

    test "rejects non-integer max_tokens" do
      assert_raise FunctionClauseError, fn ->
        WorkingContext.new("not-an-integer")
      end
    end
  end

  describe "put/4" do
    test "adds a new context item with default options" do
      ctx = WorkingContext.new()
      ctx = WorkingContext.put(ctx, :framework, "Phoenix 1.7")

      item = ctx.items[:framework]
      assert item.key == :framework
      assert item.value == "Phoenix 1.7"
      assert item.source == :explicit
      assert item.confidence == 0.8
      assert item.access_count == 1
      assert %DateTime{} = item.first_seen
      assert %DateTime{} = item.last_accessed
    end

    test "updates existing item, preserving first_seen" do
      ctx = WorkingContext.new()
      ctx = WorkingContext.put(ctx, :framework, "Phoenix 1.7")
      first_seen = ctx.items[:framework].first_seen

      # Small delay to ensure timestamp difference
      Process.sleep(10)

      ctx = WorkingContext.put(ctx, :framework, "Phoenix 1.7.1")
      item = ctx.items[:framework]

      assert item.value == "Phoenix 1.7.1"
      assert item.first_seen == first_seen
      assert item.access_count == 2
      assert DateTime.compare(item.last_accessed, first_seen) == :gt
    end

    test "accepts source option" do
      ctx = WorkingContext.new()

      ctx = WorkingContext.put(ctx, :framework, "Phoenix", source: :tool)
      assert ctx.items[:framework].source == :tool

      ctx = WorkingContext.put(ctx, :user_intent, "Build app", source: :inferred)
      assert ctx.items[:user_intent].source == :inferred
    end

    test "accepts confidence option" do
      ctx = WorkingContext.new()

      ctx = WorkingContext.put(ctx, :framework, "Phoenix", confidence: 1.0)
      assert ctx.items[:framework].confidence == 1.0

      ctx = WorkingContext.put(ctx, :primary_language, "Elixir", confidence: 0.5)
      assert ctx.items[:primary_language].confidence == 0.5
    end

    test "clamps confidence to 0.0-1.0 range" do
      ctx = WorkingContext.new()

      ctx = WorkingContext.put(ctx, :framework, "Phoenix", confidence: 1.5)
      assert ctx.items[:framework].confidence == 1.0

      ctx = WorkingContext.put(ctx, :primary_language, "Elixir", confidence: -0.5)
      assert ctx.items[:primary_language].confidence == 0.0
    end

    test "accepts memory_type override" do
      ctx = WorkingContext.new()

      ctx = WorkingContext.put(ctx, :framework, "Phoenix", memory_type: :convention)
      assert ctx.items[:framework].suggested_type == :convention
    end

    test "infers memory type when not provided" do
      ctx = WorkingContext.new()

      ctx = WorkingContext.put(ctx, :framework, "Phoenix", source: :tool)
      assert ctx.items[:framework].suggested_type == :fact

      ctx = WorkingContext.put(ctx, :user_intent, "Build app", source: :inferred)
      assert ctx.items[:user_intent].suggested_type == :assumption
    end

    test "rejects invalid context keys" do
      ctx = WorkingContext.new()

      assert_raise ArgumentError, ~r/Invalid context key/, fn ->
        WorkingContext.put(ctx, :invalid_key, "value")
      end

      assert_raise ArgumentError, ~r/Invalid context key/, fn ->
        WorkingContext.put(ctx, "string_key", "value")
      end
    end

    test "accepts all valid context keys" do
      ctx = WorkingContext.new()

      # Test all valid keys from Types.context_keys/0
      Enum.each(Types.context_keys(), fn key ->
        ctx = WorkingContext.put(ctx, key, "test value")
        assert Map.has_key?(ctx.items, key)
      end)
    end
  end

  describe "get/2" do
    test "returns value and updates access tracking for existing key" do
      ctx = WorkingContext.new()
      ctx = WorkingContext.put(ctx, :framework, "Phoenix")
      initial_count = ctx.items[:framework].access_count

      {ctx, value} = WorkingContext.get(ctx, :framework)

      assert value == "Phoenix"
      assert ctx.items[:framework].access_count == initial_count + 1
    end

    test "returns context and nil for non-existent key" do
      ctx = WorkingContext.new()

      {ctx, value} = WorkingContext.get(ctx, :framework)

      assert value == nil
      assert ctx.items == %{}
    end

    test "updates last_accessed timestamp" do
      ctx = WorkingContext.new()
      ctx = WorkingContext.put(ctx, :framework, "Phoenix")
      initial_last_accessed = ctx.items[:framework].last_accessed

      Process.sleep(10)

      {ctx, _value} = WorkingContext.get(ctx, :framework)

      assert DateTime.compare(
               ctx.items[:framework].last_accessed,
               initial_last_accessed
             ) == :gt
    end
  end

  describe "peek/2" do
    test "returns value without updating access tracking" do
      ctx = WorkingContext.new()
      ctx = WorkingContext.put(ctx, :framework, "Phoenix")
      initial_count = ctx.items[:framework].access_count
      initial_last_accessed = ctx.items[:framework].last_accessed

      Process.sleep(10)

      value = WorkingContext.peek(ctx, :framework)

      assert value == "Phoenix"
      assert ctx.items[:framework].access_count == initial_count
      assert ctx.items[:framework].last_accessed == initial_last_accessed
    end

    test "returns nil for non-existent key" do
      ctx = WorkingContext.new()

      assert WorkingContext.peek(ctx, :framework) == nil
    end
  end

  describe "delete/2" do
    test "removes item from context" do
      ctx = WorkingContext.new()
      ctx = WorkingContext.put(ctx, :framework, "Phoenix")
      assert Map.has_key?(ctx.items, :framework)

      ctx = WorkingContext.delete(ctx, :framework)

      refute Map.has_key?(ctx.items, :framework)
    end

    test "returns context unchanged for non-existent key" do
      ctx = WorkingContext.new()
      original_items = ctx.items

      ctx = WorkingContext.delete(ctx, :framework)

      assert ctx.items == original_items
    end
  end

  describe "to_list/1" do
    test "returns all items as a list" do
      ctx = WorkingContext.new()
      ctx = WorkingContext.put(ctx, :framework, "Phoenix")
      ctx = WorkingContext.put(ctx, :primary_language, "Elixir")

      items = WorkingContext.to_list(ctx)

      assert length(items) == 2
      assert Enum.any?(items, fn item -> item.key == :framework end)
      assert Enum.any?(items, fn item -> item.key == :primary_language end)
    end

    test "returns empty list for empty context" do
      ctx = WorkingContext.new()

      assert WorkingContext.to_list(ctx) == []
    end
  end

  describe "to_map/1" do
    test "returns simple key-value map without metadata" do
      ctx = WorkingContext.new()
      ctx = WorkingContext.put(ctx, :framework, "Phoenix")
      ctx = WorkingContext.put(ctx, :primary_language, "Elixir")

      map = WorkingContext.to_map(ctx)

      assert map == %{framework: "Phoenix", primary_language: "Elixir"}
      assert is_map(map)
      refute Map.has_key?(map, :access_count)
      refute Map.has_key?(map, :source)
    end

    test "returns empty map for empty context" do
      ctx = WorkingContext.new()

      assert WorkingContext.to_map(ctx) == %{}
    end
  end

  describe "size/1" do
    test "returns count of items in context" do
      ctx = WorkingContext.new()

      assert WorkingContext.size(ctx) == 0

      ctx = WorkingContext.put(ctx, :framework, "Phoenix")
      assert WorkingContext.size(ctx) == 1

      ctx = WorkingContext.put(ctx, :primary_language, "Elixir")
      assert WorkingContext.size(ctx) == 2
    end
  end

  describe "clear/1" do
    test "removes all items and resets token count" do
      ctx = WorkingContext.new(8_000)
      ctx = WorkingContext.put(ctx, :framework, "Phoenix")
      ctx = WorkingContext.put(ctx, :primary_language, "Elixir")

      ctx = WorkingContext.clear(ctx)

      assert ctx.items == %{}
      assert ctx.current_tokens == 0
      assert ctx.max_tokens == 8_000
    end
  end

  describe "has_key?/2" do
    test "returns true for existing key" do
      ctx = WorkingContext.new()
      ctx = WorkingContext.put(ctx, :framework, "Phoenix")

      assert WorkingContext.has_key?(ctx, :framework)
    end

    test "returns false for non-existent key" do
      ctx = WorkingContext.new()

      refute WorkingContext.has_key?(ctx, :framework)
    end
  end

  describe "get_item/2" do
    test "returns full item with metadata" do
      ctx = WorkingContext.new()
      ctx = WorkingContext.put(ctx, :framework, "Phoenix", source: :tool, confidence: 0.9)

      item = WorkingContext.get_item(ctx, :framework)

      assert item.key == :framework
      assert item.value == "Phoenix"
      assert item.source == :tool
      assert item.confidence == 0.9
      assert item.access_count == 1
      assert %DateTime{} = item.first_seen
      assert %DateTime{} = item.last_accessed
      assert item.suggested_type == :fact
    end

    test "returns nil for non-existent key" do
      ctx = WorkingContext.new()

      assert WorkingContext.get_item(ctx, :framework) == nil
    end
  end

  describe "infer_memory_type/2" do
    test "infers fact type for tool-sourced framework" do
      assert WorkingContext.infer_memory_type(:framework, :tool) == :fact
      assert WorkingContext.infer_memory_type(:primary_language, :tool) == :fact
      assert WorkingContext.infer_memory_type(:project_root, :tool) == :fact
      assert WorkingContext.infer_memory_type(:active_file, :tool) == :fact
    end

    test "infers assumption for inferred-sourced intent and task" do
      assert WorkingContext.infer_memory_type(:user_intent, :inferred) == :assumption
      assert WorkingContext.infer_memory_type(:current_task, :inferred) == :assumption
    end

    test "infers discovery for patterns and relationships" do
      assert WorkingContext.infer_memory_type(:discovered_patterns, :tool) == :discovery
      assert WorkingContext.infer_memory_type(:discovered_patterns, :inferred) == :discovery
      assert WorkingContext.infer_memory_type(:file_relationships, :tool) == :discovery
    end

    test "returns nil for errors and questions" do
      assert WorkingContext.infer_memory_type(:active_errors, :tool) == nil
      assert WorkingContext.infer_memory_type(:pending_questions, :explicit) == :unknown
    end

    test "returns nil for unknown key/source combinations" do
      assert WorkingContext.infer_memory_type(:framework, :inferred) == nil
      assert WorkingContext.infer_memory_type(:user_intent, :tool) == nil
    end
  end

  describe "integration tests" do
    test "full workflow: put, get, update, delete" do
      # Start with empty context
      ctx = WorkingContext.new()

      # Add some context
      ctx = WorkingContext.put(ctx, :framework, "Phoenix", source: :tool)
      ctx = WorkingContext.put(ctx, :primary_language, "Elixir", source: :tool)
      ctx = WorkingContext.put(ctx, :user_intent, "Build web app", source: :inferred)

      # Get a value (should update access count)
      {ctx, framework} = WorkingContext.get(ctx, :framework)
      assert framework == "Phoenix"
      assert ctx.items[:framework].access_count == 2

      # Peek without updating access count
      language = WorkingContext.peek(ctx, :primary_language)
      assert language == "Elixir"
      assert ctx.items[:primary_language].access_count == 1

      # Update a value
      ctx = WorkingContext.put(ctx, :framework, "Phoenix 1.7")
      assert ctx.items[:framework].value == "Phoenix 1.7"
      assert ctx.items[:framework].access_count == 3

      # Check size
      assert WorkingContext.size(ctx) == 3

      # Delete a value
      ctx = WorkingContext.delete(ctx, :user_intent)
      assert WorkingContext.size(ctx) == 2
      refute WorkingContext.has_key?(ctx, :user_intent)

      # Clear all
      ctx = WorkingContext.clear(ctx)
      assert WorkingContext.size(ctx) == 0
    end

    test "metadata tracking across multiple operations" do
      ctx = WorkingContext.new()

      # Add item
      ctx = WorkingContext.put(ctx, :framework, "Phoenix", confidence: 0.9)
      item = ctx.items[:framework]
      assert item.access_count == 1
      first_seen = item.first_seen

      # Wait and get (should increment count)
      Process.sleep(10)
      {ctx, _} = WorkingContext.get(ctx, :framework)
      item = ctx.items[:framework]
      assert item.access_count == 2
      assert item.first_seen == first_seen

      # Update
      ctx = WorkingContext.put(ctx, :framework, "Phoenix 1.7")
      item = ctx.items[:framework]
      assert item.access_count == 3
      assert item.first_seen == first_seen
      assert item.value == "Phoenix 1.7"
    end
  end
end
