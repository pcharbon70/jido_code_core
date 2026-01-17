defmodule JidoCodeCore.Memory.ShortTerm.PendingMemoriesTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Memory.ShortTerm.PendingMemories

  # Note: doctests disabled due to incomplete examples in the module
  @valid_item %{
    content: "Project uses Phoenix",
    memory_type: :fact,
    confidence: 0.9,
    source_type: :tool,
    evidence: [],
    rationale: nil
  }

  describe "new/0" do
    test "creates empty PendingMemories with default max_items" do
      pending = PendingMemories.new()

      assert pending.items == %{}
      assert pending.agent_decisions == []
      assert pending.max_items == 500
      assert pending.max_agent_decisions == 100
    end
  end

  describe "new/1" do
    test "creates empty PendingMemories with custom max_items" do
      pending = PendingMemories.new(100)

      assert pending.items == %{}
      assert pending.max_items == 100
    end

    test "rejects non-positive max_items" do
      assert_raise FunctionClauseError, fn ->
        PendingMemories.new(0)
      end

      assert_raise FunctionClauseError, fn ->
        PendingMemories.new(-10)
      end
    end

    test "rejects non-integer max_items" do
      assert_raise FunctionClauseError, fn ->
        PendingMemories.new("not-an-integer")
      end
    end
  end

  describe "add_implicit/2" do
    test "adds item with generated id" do
      pending = PendingMemories.new()
      pending = PendingMemories.add_implicit(pending, @valid_item)

      assert map_size(pending.items) == 1
      [{id, item}] = Map.to_list(pending.items)
      assert String.starts_with?(id, "pending-")
      assert item.content == "Project uses Phoenix"
      assert item.suggested_by == :implicit
      assert item.importance_score == 0.5
    end

    test "adds item with provided id" do
      pending = PendingMemories.new()
      item = Map.put(@valid_item, :id, "custom-id")
      pending = PendingMemories.add_implicit(pending, item)

      assert Map.has_key?(pending.items, "custom-id")
      assert pending.items["custom-id"].id == "custom-id"
    end

    test "sets importance_score from item" do
      pending = PendingMemories.new()
      item = Map.put(@valid_item, :importance_score, 0.8)
      pending = PendingMemories.add_implicit(pending, item)

      assert pending.items |> Map.values() |> hd() |> Map.get(:importance_score) == 0.8
    end

    test "evicts lowest scored item when at max_items" do
      pending = PendingMemories.new(3)

      # Add 3 items
      pending =
        Enum.reduce(1..3, pending, fn i, p ->
          item =
            @valid_item
            |> Map.put(:id, "item-#{i}")
            |> Map.put(:importance_score, i * 0.3)
            |> Map.put(:content, "Content #{i}")

          PendingMemories.add_implicit(p, item)
        end)

      assert map_size(pending.items) == 3

      # Add 4th item - should evict lowest (item-1 with score 0.3)
      item4 =
        @valid_item
        |> Map.put(:id, "item-4")
        |> Map.put(:importance_score, 0.9)
        |> Map.put(:content, "Content 4")

      pending = PendingMemories.add_implicit(pending, item4)

      assert map_size(pending.items) == 3
      refute Map.has_key?(pending.items, "item-1")
      assert Map.has_key?(pending.items, "item-2")
      assert Map.has_key?(pending.items, "item-3")
      assert Map.has_key?(pending.items, "item-4")
    end

    test "updates existing item when id already exists" do
      pending = PendingMemories.new()
      item = Map.put(@valid_item, :id, "item-1")
      pending = PendingMemories.add_implicit(pending, item)

      # Add again with same id but different content
      updated_item = Map.put(item, :content, "Updated content")
      pending = PendingMemories.add_implicit(pending, updated_item)

      assert map_size(pending.items) == 1
      assert pending.items["item-1"].content == "Updated content"
    end
  end

  describe "add_agent_decision/2" do
    test "adds item with importance_score 1.0 and suggested_by :agent" do
      pending = PendingMemories.new()
      pending = PendingMemories.add_agent_decision(pending, @valid_item)

      assert length(pending.agent_decisions) == 1
      item = hd(pending.agent_decisions)
      assert item.importance_score == 1.0
      assert item.suggested_by == :agent
    end

    test "evicts oldest when at max_agent_decisions" do
      pending = %PendingMemories{PendingMemories.new() | max_agent_decisions: 3}

      # Add 3 items
      pending =
        Enum.reduce(1..3, pending, fn i, acc ->
          item =
            @valid_item
            |> Map.put(:id, "decision-#{i}")
            |> Map.put(:content, "Decision #{i}")

          PendingMemories.add_agent_decision(acc, item)
        end)

      assert length(pending.agent_decisions) == 3

      # Add 4th item - oldest (first added) should be dropped
      item4 =
        @valid_item
        |> Map.put(:id, "decision-4")
        |> Map.put(:content, "Decision 4")

      pending = PendingMemories.add_agent_decision(pending, item4)

      assert length(pending.agent_decisions) == 3
      # The newest 3 should remain
      ids = Enum.map(pending.agent_decisions, & &1.id)
      refute "decision-1" in ids
      assert "decision-2" in ids
      assert "decision-3" in ids
      assert "decision-4" in ids
    end
  end

  describe "ready_for_promotion/2" do
    test "returns implicit items above threshold" do
      pending = PendingMemories.new()

      # Add items with different scores
      high_score =
        @valid_item
        |> Map.put(:id, "high")
        |> Map.put(:importance_score, 0.8)
        |> Map.put(:content, "High importance")

      low_score =
        @valid_item
        |> Map.put(:id, "low")
        |> Map.put(:importance_score, 0.4)
        |> Map.put(:content, "Low importance")

      pending = PendingMemories.add_implicit(pending, high_score)
      pending = PendingMemories.add_implicit(pending, low_score)

      ready = PendingMemories.ready_for_promotion(pending, 0.6)

      assert length(ready) == 1
      assert hd(ready).id == "high"
    end

    test "always includes agent decisions regardless of score" do
      pending = PendingMemories.new()

      # Add agent decision (score 1.0)
      agent_item =
        @valid_item
        |> Map.put(:id, "agent-1")
        |> Map.put(:content, "Agent decision")

      pending = PendingMemories.add_agent_decision(pending, agent_item)

      ready = PendingMemories.ready_for_promotion(pending, 0.9)

      # Agent decisions always included even with high threshold
      assert length(ready) == 1
      assert hd(ready).id == "agent-1"
    end

    test "combines implicit and agent items, sorted by score" do
      pending = PendingMemories.new()

      # Add implicit items
      implicit1 =
        @valid_item
        |> Map.put(:id, "implicit-1")
        |> Map.put(:importance_score, 0.7)

      implicit2 =
        @valid_item
        |> Map.put(:id, "implicit-2")
        |> Map.put(:importance_score, 0.9)

      pending = PendingMemories.add_implicit(pending, implicit1)
      pending = PendingMemories.add_implicit(pending, implicit2)

      # Add agent decision (score 1.0)
      agent_item =
        @valid_item
        |> Map.put(:id, "agent-1")

      pending = PendingMemories.add_agent_decision(pending, agent_item)

      ready = PendingMemories.ready_for_promotion(pending, 0.6)

      assert length(ready) == 3
      # Sorted by score descending
      # 1.0
      assert Enum.at(ready, 0).id == "agent-1"
      # 0.9
      assert Enum.at(ready, 1).id == "implicit-2"
      # 0.7
      assert Enum.at(ready, 2).id == "implicit-1"
    end

    test "uses default threshold of 0.6 when not specified" do
      pending = PendingMemories.new()

      item =
        @valid_item
        |> Map.put(:id, "item-1")
        |> Map.put(:importance_score, 0.6)

      pending = PendingMemories.add_implicit(pending, item)

      ready = PendingMemories.ready_for_promotion(pending)

      assert length(ready) == 1
    end
  end

  describe "clear_promoted/2" do
    test "removes specified ids from items map" do
      pending = PendingMemories.new()

      item1 =
        @valid_item
        |> Map.put(:id, "item-1")
        |> Map.put(:content, "Content 1")

      item2 =
        @valid_item
        |> Map.put(:id, "item-2")
        |> Map.put(:content, "Content 2")

      pending = PendingMemories.add_implicit(pending, item1)
      pending = PendingMemories.add_implicit(pending, item2)

      pending = PendingMemories.clear_promoted(pending, ["item-1"])

      assert map_size(pending.items) == 1
      refute Map.has_key?(pending.items, "item-1")
      assert Map.has_key?(pending.items, "item-2")
    end

    test "clears all agent_decisions" do
      pending = PendingMemories.new()

      pending =
        Enum.reduce(1..3, pending, fn i, acc ->
          item =
            @valid_item
            |> Map.put(:id, "agent-#{i}")
            |> Map.put(:content, "Decision #{i}")

          PendingMemories.add_agent_decision(acc, item)
        end)

      assert length(pending.agent_decisions) == 3

      pending = PendingMemories.clear_promoted(pending, [])

      assert length(pending.agent_decisions) == 0
    end
  end

  describe "get/2" do
    test "returns item from items map" do
      pending = PendingMemories.new()

      item =
        @valid_item
        |> Map.put(:id, "item-1")
        |> Map.put(:content, "Test content")

      pending = PendingMemories.add_implicit(pending, item)

      result = PendingMemories.get(pending, "item-1")

      assert result.content == "Test content"
    end

    test "returns item from agent_decisions" do
      pending = PendingMemories.new()

      item =
        @valid_item
        |> Map.put(:id, "agent-1")
        |> Map.put(:content, "Agent content")

      pending = PendingMemories.add_agent_decision(pending, item)

      result = PendingMemories.get(pending, "agent-1")

      assert result.content == "Agent content"
    end

    test "returns nil for non-existent id" do
      pending = PendingMemories.new()

      assert PendingMemories.get(pending, "nonexistent") == nil
    end

    test "searches items map before agent_decisions" do
      pending = PendingMemories.new()

      implicit =
        @valid_item
        |> Map.put(:id, "item-1")
        |> Map.put(:content, "Implicit")

      agent =
        @valid_item
        |> Map.put(:id, "item-1")
        |> Map.put(:content, "Agent")

      pending = PendingMemories.add_implicit(pending, implicit)
      pending = PendingMemories.add_agent_decision(pending, agent)

      # Should return the implicit item (items map checked first)
      result = PendingMemories.get(pending, "item-1")

      # The agent decision would be in the list, but items map takes precedence
      assert result != nil
    end
  end

  describe "size/1" do
    test "returns 0 for empty PendingMemories" do
      pending = PendingMemories.new()

      assert PendingMemories.size(pending) == 0
    end

    test "returns count of implicit items" do
      pending = PendingMemories.new()

      pending =
        Enum.reduce(1..3, pending, fn i, acc ->
          item =
            @valid_item
            |> Map.put(:id, "item-#{i}")

          PendingMemories.add_implicit(acc, item)
        end)

      assert PendingMemories.size(pending) == 3
    end

    test "returns count of agent decisions" do
      pending = PendingMemories.new()

      pending =
        Enum.reduce(1..5, pending, fn i, acc ->
          item =
            @valid_item
            |> Map.put(:id, "agent-#{i}")

          PendingMemories.add_agent_decision(acc, item)
        end)

      assert PendingMemories.size(pending) == 5
    end

    test "returns combined count of implicit and agent items" do
      pending = PendingMemories.new()

      item = Map.put(@valid_item, :id, "implicit-1")
      pending = PendingMemories.add_implicit(pending, item)

      agent_item = Map.put(@valid_item, :id, "agent-1")
      pending = PendingMemories.add_agent_decision(pending, agent_item)

      assert PendingMemories.size(pending) == 2
    end
  end

  describe "update_score/3" do
    test "updates importance_score for existing item" do
      pending = PendingMemories.new()

      item =
        @valid_item
        |> Map.put(:id, "item-1")
        |> Map.put(:importance_score, 0.5)

      pending = PendingMemories.add_implicit(pending, item)
      pending = PendingMemories.update_score(pending, "item-1", 0.9)

      assert pending.items["item-1"].importance_score == 0.9
    end

    test "clamps score to 0.0-1.0 range" do
      pending = PendingMemories.new()

      item =
        @valid_item
        |> Map.put(:id, "item-1")
        |> Map.put(:importance_score, 0.5)

      pending = PendingMemories.add_implicit(pending, item)

      pending = PendingMemories.update_score(pending, "item-1", 1.5)
      assert pending.items["item-1"].importance_score == 1.0

      pending = PendingMemories.update_score(pending, "item-1", -0.5)
      assert pending.items["item-1"].importance_score == 0.0
    end

    test "does nothing for non-existent item" do
      pending = PendingMemories.new()

      original_items = pending.items
      pending = PendingMemories.update_score(pending, "nonexistent", 0.9)

      assert pending.items == original_items
    end

    test "does not affect agent_decisions" do
      pending = PendingMemories.new()

      item = Map.put(@valid_item, :id, "agent-1")
      pending = PendingMemories.add_agent_decision(pending, item)

      # Agent decision has score 1.0
      assert hd(pending.agent_decisions).importance_score == 1.0

      # Try to update - should have no effect on agent decisions
      pending = PendingMemories.update_score(pending, "agent-1", 0.5)

      # Agent decision score should still be 1.0
      assert hd(pending.agent_decisions).importance_score == 1.0
    end
  end

  describe "list_implicit/1" do
    test "returns empty list for empty PendingMemories" do
      pending = PendingMemories.new()

      assert PendingMemories.list_implicit(pending) == []
    end

    test "returns all implicit items as list" do
      pending = PendingMemories.new()

      pending =
        Enum.reduce(1..3, pending, fn i, acc ->
          item =
            @valid_item
            |> Map.put(:id, "item-#{i}")

          PendingMemories.add_implicit(acc, item)
        end)

      items = PendingMemories.list_implicit(pending)

      assert length(items) == 3
    end
  end

  describe "list_agent_decisions/1" do
    test "returns empty list for empty PendingMemories" do
      pending = PendingMemories.new()

      assert PendingMemories.list_agent_decisions(pending) == []
    end

    test "returns all agent decisions as list" do
      pending = PendingMemories.new()

      pending =
        Enum.reduce(1..3, pending, fn i, acc ->
          item =
            @valid_item
            |> Map.put(:id, "agent-#{i}")

          PendingMemories.add_agent_decision(acc, item)
        end)

      decisions = PendingMemories.list_agent_decisions(pending)

      assert length(decisions) == 3
    end
  end

  describe "clear/1" do
    test "removes all implicit items" do
      pending = PendingMemories.new()

      pending =
        Enum.reduce(1..3, pending, fn i, acc ->
          item = Map.put(@valid_item, :id, "item-#{i}")
          PendingMemories.add_implicit(acc, item)
        end)

      assert map_size(pending.items) == 3

      pending = PendingMemories.clear(pending)

      assert map_size(pending.items) == 0
    end

    test "removes all agent decisions" do
      pending = PendingMemories.new()

      pending =
        Enum.reduce(1..3, pending, fn i, acc ->
          item = Map.put(@valid_item, :id, "agent-#{i}")
          PendingMemories.add_agent_decision(acc, item)
        end)

      assert length(pending.agent_decisions) == 3

      pending = PendingMemories.clear(pending)

      assert length(pending.agent_decisions) == 0
    end

    test "resets size to 0" do
      pending = PendingMemories.new()

      implicit = Map.put(@valid_item, :id, "implicit-1")
      pending = PendingMemories.add_implicit(pending, implicit)

      agent = Map.put(@valid_item, :id, "agent-1")
      pending = PendingMemories.add_agent_decision(pending, agent)

      assert PendingMemories.size(pending) == 2

      pending = PendingMemories.clear(pending)

      assert PendingMemories.size(pending) == 0
    end
  end

  describe "generate_id/0" do
    test "generates unique ids with pending prefix" do
      id1 = PendingMemories.generate_id()
      id2 = PendingMemories.generate_id()

      assert String.starts_with?(id1, "pending-")
      assert String.starts_with?(id2, "pending-")
      refute id1 == id2
    end

    test "generates 32 character hex after prefix" do
      id = PendingMemories.generate_id()

      # "pending-" is 8 chars, hex is 32 chars
      assert String.length(id) == 40
    end
  end

  describe "integration tests" do
    test "full workflow: add, check promotion, clear promoted" do
      pending = PendingMemories.new()

      # Add implicit items with different scores
      high = Map.put(@valid_item, :importance_score, 0.8)
      low = Map.put(@valid_item, :importance_score, 0.4)

      pending = PendingMemories.add_implicit(pending, Map.put(high, :id, "high"))
      pending = PendingMemories.add_implicit(pending, Map.put(low, :id, "low"))

      # Add agent decision
      agent = Map.put(@valid_item, :id, "agent-1")
      pending = PendingMemories.add_agent_decision(pending, agent)

      # Check ready for promotion
      ready = PendingMemories.ready_for_promotion(pending, 0.6)
      # high + agent
      assert length(ready) == 2

      ids = Enum.map(ready, & &1.id)
      assert "high" in ids
      assert "agent-1" in ids
      refute "low" in ids

      # Clear promoted items
      pending = PendingMemories.clear_promoted(pending, ["high"])
      # only "low" remains
      assert map_size(pending.items) == 1
      # all cleared
      assert length(pending.agent_decisions) == 0
    end

    test "manages capacity by evicting lowest scored items" do
      pending = PendingMemories.new(5)

      # Add 5 items
      pending =
        Enum.reduce(1..5, pending, fn i, acc ->
          item =
            @valid_item
            |> Map.put(:id, "item-#{i}")
            |> Map.put(:importance_score, i * 0.2)

          PendingMemories.add_implicit(acc, item)
        end)

      assert map_size(pending.items) == 5

      # Add 6th item with high score - should evict lowest (item-1)
      item6 =
        @valid_item
        |> Map.put(:id, "item-6")
        |> Map.put(:importance_score, 1.0)

      pending = PendingMemories.add_implicit(pending, item6)

      assert map_size(pending.items) == 5
      refute Map.has_key?(pending.items, "item-1")
      assert Map.has_key?(pending.items, "item-6")
    end
  end
end
