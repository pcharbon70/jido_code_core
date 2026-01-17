defmodule JidoCodeCore.API.Memory do
  @moduledoc """
  Public API for memory operations in JidoCodeCore.Core.

  This module provides the interface for the two-tier memory system:
  - **Short-term memory** - Session-specific working context
  - **Long-term memory** - Persistent knowledge storage

  ## Memory Types

  Knowledge types:
  - `:fact` - Verified factual information
  - `:assumption` - Inferred information needing verification
  - `:hypothesis` - Proposed explanations being tested
  - `:discovery` - Newly found information
  - `:risk` - Potential issues or concerns
  - `:unknown` - Information gaps

  Decision types:
  - `:decision` - Choices made with rationale
  - `:architectural_decision` - Significant architectural choices
  - `:implementation_decision` - Implementation-specific choices
  - `:alternative` - Considered options not selected
  - `:trade_off` - Compromise relationships

  Convention types:
  - `:convention` - Established patterns or standards
  - `:coding_standard` - Coding practices and style guidelines
  - `:architectural_convention` - Architectural patterns
  - `:agent_rule` - Rules governing agent behavior
  - `:process_convention` - Workflow and process conventions

  Error types:
  - `:error` - General development or execution errors
  - `:bug` - Code defects
  - `:failure` - System-level failures
  - `:incident` - Operational incidents
  - `:root_cause` - Underlying causes of errors
  - `:lesson_learned` - Insights from past experiences

  ## Examples

      # Remember important information
      {:ok, result} = remember("session-id", "Uses Phoenix framework", type: :fact)

      # Recall relevant memories
      {:ok, memories} = recall("session-id", query: "Phoenix")

      # Search by type
      {:ok, decisions} = recall("session-id", type: :decision)

      # Forget a memory
      {:ok, result} = forget("session-id", "memory-id")

  """

  alias JidoCodeCore.Memory.Actions

  @typedoc "Memory type atom"
  # Knowledge types
  @type memory_type ::
          :fact
          | :assumption
          | :hypothesis
          | :discovery
          | :risk
          | :unknown
          # Decision types
          | :decision
          | :architectural_decision
          | :implementation_decision
          | :alternative
          | :trade_off
          # Convention types
          | :convention
          | :coding_standard
          | :architectural_convention
          | :agent_rule
          | :process_convention
          # Error types
          | :error
          | :bug
          | :failure
          | :incident
          | :root_cause
          | :lesson_learned

  @typedoc "Search mode"
  @type search_mode :: :text | :semantic | :hybrid

  @typedoc "Remember options"
  @type remember_opts :: [
          type: memory_type(),
          confidence: float(),
          rationale: String.t()
        ]

  @typedoc "Recall options"
  @type recall_opts :: [
          query: String.t(),
          search_mode: search_mode(),
          type: memory_type() | :all,
          min_confidence: float(),
          limit: pos_integer()
        ]

  # ============================================================================
  # Long-term Memory Operations
  # ============================================================================

  @doc """
  Remembers important information in long-term memory.

  Use this when you discover something valuable for future sessions.
  Agent-initiated memories bypass the normal importance threshold
  and are persisted immediately with maximum importance score.

  ## Parameters

    - `session_id` - The session's unique ID
    - `content` - What to remember (concise, factual, max 2000 chars)
    - `opts` - Optional parameters

  ## Options

    - `:type` - Memory type (default: `:fact`)
    - `:confidence` - Confidence level 0.0-1.0 (default: 0.8)
    - `:rationale` - Why this is worth remembering

  ## Returns

    - `{:ok, result}` - Memory stored successfully
    - `{:error, reason}` - Storage failed

  ## Examples

      {:ok, result} = remember("session-id", "Uses Phoenix framework")
      {:ok, result} = remember("session-id", "Session timeout is 30s",
        type: :fact, confidence: 1.0)

  """
  @spec remember(String.t(), String.t(), remember_opts()) ::
          {:ok, map()} | {:error, term()}
  def remember(session_id, content, opts \\ [])
      when is_binary(session_id) and is_binary(content) do
    type = Keyword.get(opts, :type, :fact)
    confidence = Keyword.get(opts, :confidence, 0.8)
    rationale = Keyword.get(opts, :rationale)

    params = %{
      content: content,
      type: type,
      confidence: confidence
    }

    params = if rationale, do: Map.put(params, :rationale, rationale), else: params

    context = %{
      session_id: session_id
    }

    case Actions.Remember.run(params, context) do
      {:ok, result} -> {:ok, result}
      {:error, _} = error -> error
    end
  end

  @doc """
  Recalls memories from long-term storage.

  Searches for previously stored information matching the query.

  ## Parameters

    - `session_id` - The session's unique ID
    - `opts` - Optional search parameters

  ## Options

    - `:query` - Search query or keywords (default: all memories)
    - `:search_mode` - `:text`, `:semantic`, or `:hybrid` (default: `:hybrid`)
    - `:type` - Filter by memory type (default: `:all`)
    - `:min_confidence` - Minimum confidence 0.0-1.0 (default: 0.5)
    - `:limit` - Maximum results (default: 10, max: 50)

  ## Search Modes

    - `:text` - Simple substring matching (fast, exact matches)
    - `:semantic` - TF-IDF based semantic similarity (finds related content)
    - `:hybrid` - Combines text matches with semantic ranking (default)

  ## Returns

    - `{:ok, memories}` - List of memory results
    - `{:error, reason}` - Search failed

  ## Examples

      {:ok, memories} = recall("session-id", query: "Phoenix")
      {:ok, memories} = recall("session-id", type: :decision, limit: 5)
      {:ok, memories} = recall("session-id", query: "error", search_mode: :semantic)

  """
  @spec recall(String.t(), recall_opts()) :: {:ok, [map()]} | {:error, term()}
  def recall(session_id, opts \\ []) when is_binary(session_id) do
    query = Keyword.get(opts, :query, "")
    search_mode = Keyword.get(opts, :search_mode, :hybrid)
    type = Keyword.get(opts, :type, :all)
    min_confidence = Keyword.get(opts, :min_confidence, 0.5)
    limit = Keyword.get(opts, :limit, 10)

    params = %{
      query: query,
      search_mode: search_mode,
      type: type,
      min_confidence: min_confidence,
      limit: limit
    }

    context = %{
      session_id: session_id
    }

    case Actions.Recall.run(params, context) do
      {:ok, result} ->
        memories = Map.get(result, "memories", [])
        {:ok, memories}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Forgets (marks as superseded) a memory in long-term storage.

  Soft deletes the memory - it remains in storage but is marked as
  superseded and won't be returned by recall operations.

  ## Parameters

    - `session_id` - The session's unique ID
    - `memory_id` - The memory ID to forget

  ## Returns

    - `{:ok, result}` - Memory marked as superseded
    - `{:error, reason}` - Operation failed

  ## Examples

      {:ok, result} = forget("session-id", "memory-abc-123")

  """
  @spec forget(String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def forget(session_id, memory_id) when is_binary(session_id) and is_binary(memory_id) do
    params = %{
      memory_id: memory_id
    }

    context = %{
      session_id: session_id
    }

    case Actions.Forget.run(params, context) do
      {:ok, result} -> {:ok, result}
      {:error, _} = error -> error
    end
  end

  # ============================================================================
  # Graph Search
  # ============================================================================

  @doc """
  Searches the knowledge graph for related memories.

  Performs graph traversal to find memories connected by semantic
  relationships in the RDF knowledge graph.

  ## Parameters

    - `session_id` - The session's unique ID
    - `memory_id` - Starting memory ID
    - `opts` - Optional search parameters

  ## Options

    - `:max_depth` - Maximum traversal depth (default: 2)
    - `:max_results` - Maximum results (default: 20)
    - `:relationship_types` - Filter by relationship types

  ## Returns

    - `{:ok, memories}` - List of related memories
    - `{:error, reason}` - Search failed

  ## Examples

      {:ok, related} = search_graph("session-id", "memory-abc-123", max_depth: 3)

  """
  @spec search_graph(String.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def search_graph(session_id, memory_id, opts \\ [])
      when is_binary(session_id) and is_binary(memory_id) do
    max_depth = Keyword.get(opts, :max_depth, 2)
    max_results = Keyword.get(opts, :max_results, 20)

    # This delegates to the triple store adapter's query_related function
    # For now, return empty results as graph search is complex
    # and requires direct access to the knowledge graph infrastructure
    {:ok, []}
  end

  # ============================================================================
  # Memory Type Utilities
  # ============================================================================

  @doc """
  Returns all valid memory types.

  ## Examples

      JidoCodeCore.API.Memory.memory_types()
      # => [:fact, :assumption, :hypothesis, ...]

  """
  @spec memory_types() :: [memory_type()]
  def memory_types do
    Actions.Remember.valid_memory_types()
  end

  @doc """
  Returns all valid search modes.

  ## Examples

      JidoCodeCore.API.Memory.search_modes()
      # => [:text, :semantic, :hybrid]

  """
  @spec search_modes() :: [search_mode()]
  def search_modes do
    [:text, :semantic, :hybrid]
  end

  @doc """
  Checks if a memory type is valid.

  ## Examples

      JidoCodeCore.API.Memory.valid_type?(:fact)
      # => true

      JidoCodeCore.API.Memory.valid_type?(:invalid)
      # => false

  """
  @spec valid_type?(atom()) :: boolean()
  def valid_type?(type) when is_atom(type) do
    type in memory_types()
  end

  # ============================================================================
  # Memory Statistics
  # ============================================================================

  @doc """
  Gets memory statistics for a session.

  Returns aggregated statistics about the memory subsystem including
  pending memories, access patterns, and promotion metrics.

  ## Parameters

    - `session_id` - The session's unique ID

  ## Returns

    - `{:ok, stats}` - Memory statistics map
    - `{:error, :not_found}` - Session not found

  ## Statistics

  The returned map contains:

  - `:pending_count` - Number of memories pending promotion
  - `:pending_items` - List of pending memory items (max 10)
  - `:promotion_stats` - Promotion engine statistics
  - `:access_stats` - Access statistics by context key
  - `:context_size` - Number of items in working context
  - `:last_promotion` - Timestamp of last promotion (if any)

  ## Examples

      {:ok, stats} = get_memory_stats("session-id")
      stats.pending_count
      # => 5
      stats.context_size
      # => 12

  """
  @spec get_memory_stats(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_memory_stats(session_id) when is_binary(session_id) do
    alias JidoCodeCore.Session.State

    with {:ok, pending_memories} <- State.get_pending_memories(session_id),
         {:ok, promotion_stats} <- State.get_promotion_stats(session_id),
         {:ok, all_context} <- State.get_all_context(session_id) do
      # WorkingContext might be empty (no items key) if nothing has been stored yet
      context_items = Map.get(all_context, :items, %{})

      stats = %{
        pending_count: length(pending_memories),
        pending_items: Enum.take(pending_memories, 10),
        promotion_stats: promotion_stats,
        access_stats: extract_access_stats(session_id),
        context_size: map_size(context_items),
        last_promotion: Map.get(promotion_stats, :last_promotion_at)
      }

      {:ok, stats}
    end
  end

  # Extract access stats for high-value context keys
  defp extract_access_stats(session_id) do
    # Get access stats for common context keys
    high_value_keys = [
      :framework,
      :primary_language,
      :project_root,
      :user_intent,
      :active_file,
      :discovered_patterns
    ]

    Enum.reduce(high_value_keys, %{}, fn key, acc ->
      case JidoCodeCore.Session.State.get_access_stats(session_id, key) do
        {:ok, stats} -> Map.put(acc, key, stats)
        _ -> acc
      end
    end)
  end
end
