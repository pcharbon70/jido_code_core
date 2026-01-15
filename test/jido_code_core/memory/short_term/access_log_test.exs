defmodule JidoCodeCore.Memory.ShortTerm.AccessLogTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Memory.ShortTerm.AccessLog

  # Note: doctests disabled due to issues with AccessLog module's doctests
  # The module's doctests reference undefined variables (e.g., `log` without defining it)

  describe "new/0" do
    test "creates empty log with default max_entries" do
      log = AccessLog.new()

      assert log.entries == []
      assert log.entry_count == 0
      assert log.max_entries == 1000
    end
  end

  describe "new/1" do
    test "creates empty log with custom max_entries" do
      log = AccessLog.new(500)

      assert log.entries == []
      assert log.max_entries == 500
    end

    test "rejects non-positive max_entries" do
      assert_raise FunctionClauseError, fn ->
        AccessLog.new(0)
      end

      assert_raise FunctionClauseError, fn ->
        AccessLog.new(-100)
      end
    end

    test "rejects non-integer max_entries" do
      assert_raise FunctionClauseError, fn ->
        AccessLog.new("not-an-integer")
      end
    end
  end

  describe "record/3" do
    test "records read access" do
      log = AccessLog.new()
      log = AccessLog.record(log, :framework, :read)

      assert AccessLog.size(log) == 1
      [entry] = log.entries
      assert entry.key == :framework
      assert entry.access_type == :read
      assert %DateTime{} = entry.timestamp
    end

    test "records write access" do
      log = AccessLog.new()
      log = AccessLog.record(log, :framework, :write)

      [entry] = log.entries
      assert entry.access_type == :write
    end

    test "records query access" do
      log = AccessLog.new()
      log = AccessLog.record(log, {:memory, "mem-123"}, :query)

      [entry] = log.entries
      assert entry.key == {:memory, "mem-123"}
      assert entry.access_type == :query
    end

    test "prepends new entries (newest first)" do
      log = AccessLog.new()
      log = AccessLog.record(log, :first, :read)
      log = AccessLog.record(log, :second, :read)
      log = AccessLog.record(log, :third, :read)

      assert hd(log.entries).key == :third
      assert Enum.at(log.entries, 1).key == :second
      assert Enum.at(log.entries, 2).key == :first
    end

    test "rejects invalid access_type" do
      log = AccessLog.new()

      assert_raise FunctionClauseError, fn ->
        AccessLog.record(log, :framework, :invalid)
      end
    end

    test "enforces max_entries limit by dropping oldest" do
      log = AccessLog.new(3)

      log = AccessLog.record(log, :first, :read)
      log = AccessLog.record(log, :second, :read)
      log = AccessLog.record(log, :third, :read)

      assert AccessLog.size(log) == 3

      # Add 4th entry - should drop oldest (:first)
      log = AccessLog.record(log, :fourth, :read)

      assert AccessLog.size(log) == 3
      keys = Enum.map(log.entries, & &1.key)
      refute :first in keys
      assert :second in keys
      assert :third in keys
      assert :fourth in keys
    end

    test "handles memory tuple keys" do
      log = AccessLog.new()
      log = AccessLog.record(log, {:memory, "mem-1"}, :read)
      log = AccessLog.record(log, {:memory, "mem-2"}, :query)

      assert AccessLog.size(log) == 2
      assert hd(log.entries).key == {:memory, "mem-2"}
    end
  end

  describe "get_frequency/2" do
    test "returns 0 for key never accessed" do
      log = AccessLog.new()

      assert AccessLog.get_frequency(log, :framework) == 0
    end

    test "counts all accesses for a key" do
      log = AccessLog.new()
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :framework, :write)
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :other, :read)

      assert AccessLog.get_frequency(log, :framework) == 3
      assert AccessLog.get_frequency(log, :other) == 1
    end

    test "handles memory tuple keys" do
      log = AccessLog.new()
      log = AccessLog.record(log, {:memory, "mem-1"}, :read)
      log = AccessLog.record(log, {:memory, "mem-1"}, :query)

      assert AccessLog.get_frequency(log, {:memory, "mem-1"}) == 2
    end
  end

  describe "get_recency/2" do
    test "returns nil for key never accessed" do
      log = AccessLog.new()

      assert AccessLog.get_recency(log, :framework) == nil
    end

    test "returns most recent access timestamp" do
      log = AccessLog.new()

      log = AccessLog.record(log, :framework, :read)
      first_time = AccessLog.get_recency(log, :framework)

      Process.sleep(10)

      log = AccessLog.record(log, :framework, :write)
      second_time = AccessLog.get_recency(log, :framework)

      assert DateTime.compare(second_time, first_time) == :gt
    end

    test "handles memory tuple keys" do
      log = AccessLog.new()
      log = AccessLog.record(log, {:memory, "mem-1"}, :read)

      assert %DateTime{} = AccessLog.get_recency(log, {:memory, "mem-1"})
    end
  end

  describe "get_stats/2" do
    test "returns frequency and recency for accessed key" do
      log = AccessLog.new()
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :framework, :read)

      stats = AccessLog.get_stats(log, :framework)

      assert stats.frequency == 2
      assert %DateTime{} = stats.recency
    end

    test "returns zero frequency and nil recency for unaccessed key" do
      log = AccessLog.new()

      stats = AccessLog.get_stats(log, :framework)

      assert stats.frequency == 0
      assert stats.recency == nil
    end
  end

  describe "recent_accesses/2" do
    test "returns all entries when n exceeds count" do
      log = AccessLog.new()
      log = AccessLog.record(log, :first, :read)
      log = AccessLog.record(log, :second, :read)

      recent = AccessLog.recent_accesses(log, 10)

      assert length(recent) == 2
    end

    test "returns n most recent entries" do
      log = AccessLog.new()
      log = AccessLog.record(log, :first, :read)
      log = AccessLog.record(log, :second, :read)
      log = AccessLog.record(log, :third, :read)

      recent = AccessLog.recent_accesses(log, 2)

      assert length(recent) == 2
      assert hd(recent).key == :third
      assert Enum.at(recent, 1).key == :second
    end

    test "rejects non-positive n" do
      log = AccessLog.new()

      assert_raise FunctionClauseError, fn ->
        AccessLog.recent_accesses(log, 0)
      end

      assert_raise FunctionClauseError, fn ->
        AccessLog.recent_accesses(log, -1)
      end
    end

    test "rejects non-integer n" do
      log = AccessLog.new()

      assert_raise FunctionClauseError, fn ->
        AccessLog.recent_accesses(log, "not-an-integer")
      end
    end
  end

  describe "clear/1" do
    test "removes all entries" do
      log = AccessLog.new()
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :primary_language, :write)

      assert AccessLog.size(log) == 2

      log = AccessLog.clear(log)

      assert AccessLog.size(log) == 0
      assert log.entries == []
    end

    test "preserves max_entries setting" do
      log = AccessLog.new(500)
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.clear(log)

      assert log.max_entries == 500
    end
  end

  describe "size/1" do
    test "returns 0 for new log" do
      log = AccessLog.new()

      assert AccessLog.size(log) == 0
    end

    test "returns count of entries" do
      log = AccessLog.new()

      log =
        Enum.reduce(1..5, log, fn _, acc ->
          AccessLog.record(acc, :framework, :read)
        end)

      assert AccessLog.size(log) == 5
    end

    test "uses tracked entry_count not length" do
      log = AccessLog.new()

      log =
        Enum.reduce(1..3, log, fn _, acc ->
          AccessLog.record(acc, :framework, :read)
        end)

      assert log.entry_count == 3
      assert AccessLog.size(log) == 3
    end
  end

  describe "entries_for/2" do
    test "returns empty list for key with no entries" do
      log = AccessLog.new()

      assert AccessLog.entries_for(log, :framework) == []
    end

    test "returns all entries for a key in chronological order" do
      log = AccessLog.new()
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :other, :write)
      log = AccessLog.record(log, :framework, :write)

      entries = AccessLog.entries_for(log, :framework)

      assert length(entries) == 2
      # Newest first (entries are prepended)
      assert hd(entries).access_type == :write
      assert Enum.at(entries, 1).access_type == :read
    end

    test "handles memory tuple keys" do
      log = AccessLog.new()
      log = AccessLog.record(log, {:memory, "mem-1"}, :read)
      log = AccessLog.record(log, {:memory, "mem-2"}, :query)
      log = AccessLog.record(log, {:memory, "mem-1"}, :write)

      entries = AccessLog.entries_for(log, {:memory, "mem-1"})

      assert length(entries) == 2
    end
  end

  describe "unique_keys/1" do
    test "returns empty list for empty log" do
      log = AccessLog.new()

      assert AccessLog.unique_keys(log) == []
    end

    test "returns unique keys accessed" do
      log = AccessLog.new()
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :framework, :write)
      log = AccessLog.record(log, :primary_language, :read)

      keys = AccessLog.unique_keys(log)

      assert length(keys) == 2
      assert :framework in keys
      assert :primary_language in keys
    end

    test "includes both context keys and memory tuples" do
      log = AccessLog.new()
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, {:memory, "mem-1"}, :query)

      keys = AccessLog.unique_keys(log)

      assert length(keys) == 2
      assert :framework in keys
      assert {:memory, "mem-1"} in keys
    end
  end

  describe "access_type_counts/2" do
    test "returns zero counts for key with no entries" do
      log = AccessLog.new()

      counts = AccessLog.access_type_counts(log, :framework)

      assert counts == %{read: 0, write: 0, query: 0}
    end

    test "counts accesses by type for a key" do
      log = AccessLog.new()
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :framework, :write)
      log = AccessLog.record(log, :framework, :query)
      log = AccessLog.record(log, :other, :read)

      counts = AccessLog.access_type_counts(log, :framework)

      assert counts.read == 2
      assert counts.write == 1
      assert counts.query == 1
    end

    test "does not include other keys in counts" do
      log = AccessLog.new()
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :other, :read)
      log = AccessLog.record(log, :other, :write)

      counts = AccessLog.access_type_counts(log, :framework)

      assert counts.read == 1
      assert counts.write == 0
      assert counts.query == 0
    end
  end

  describe "integration tests" do
    test "full workflow: record, query stats, clear" do
      log = AccessLog.new()

      # Record various accesses
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :framework, :read)
      log = AccessLog.record(log, :framework, :write)
      log = AccessLog.record(log, :primary_language, :read)
      log = AccessLog.record(log, {:memory, "mem-1"}, :query)

      # Check stats
      framework_stats = AccessLog.get_stats(log, :framework)
      assert framework_stats.frequency == 3
      assert %DateTime{} = framework_stats.recency

      language_stats = AccessLog.get_stats(log, :primary_language)
      assert language_stats.frequency == 1

      mem_stats = AccessLog.get_stats(log, {:memory, "mem-1"})
      assert mem_stats.frequency == 1

      # Check type counts
      framework_counts = AccessLog.access_type_counts(log, :framework)
      assert framework_counts.read == 2
      assert framework_counts.write == 1

      # Clear and verify
      log = AccessLog.clear(log)
      assert AccessLog.size(log) == 0
    end

    test "handles eviction correctly with tracked count" do
      log = AccessLog.new(5)

      # Add 5 items
      log =
        Enum.reduce(1..5, log, fn i, acc ->
          AccessLog.record(acc, :"item-#{i}", :read)
        end)

      assert log.entry_count == 5
      assert AccessLog.size(log) == 5

      # Add 6th item - should evict oldest
      log = AccessLog.record(log, :item_6, :read)

      # Count should be capped at max_entries
      assert log.entry_count == 5
      assert AccessLog.size(log) == 5
      assert length(log.entries) == 5
    end

    test "tracks different keys independently" do
      log = AccessLog.new()

      log =
        Enum.reduce(1..3, log, fn _, acc ->
          AccessLog.record(acc, :framework, :read)
        end)

      log =
        Enum.reduce(1..2, log, fn _, acc ->
          AccessLog.record(acc, :primary_language, :read)
        end)

      log = AccessLog.record(log, :project_root, :write)

      assert AccessLog.get_frequency(log, :framework) == 3
      assert AccessLog.get_frequency(log, :primary_language) == 2
      assert AccessLog.get_frequency(log, :project_root) == 1

      keys = AccessLog.unique_keys(log)
      assert length(keys) == 3
    end
  end
end
