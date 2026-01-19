defmodule JidoCodeCore.Errors.Memory do
  @moduledoc """
  Memory-related errors.

  ## Error Types

  - `MemoryNotFound` - Memory entry not found
  - `MemoryStorageFailed` - Failed to store memory entry
  - `MemoryPromotionFailed` - Failed to promote memory to long-term storage

  ## Examples

      raise Errors.Memory.MemoryNotFound.exception(
        memory_id: "mem-123",
        query: "what did i work on yesterday"
      )

      raise Errors.Memory.MemoryStorageFailed.exception(
        reason: "disk full",
        content: "some memory content"
      )

      raise Errors.Memory.MemoryPromotionFailed.exception(
        memory_id: "mem-123",
        reason: "triple_store_unavailable"
      )
  """

  defmodule MemoryNotFound do
    @moduledoc """
    Error raised when a memory entry is not found.
    """
    defexception [:message, :memory_id, :query, :details]

    @impl true
    def exception(opts) do
      memory_id = Keyword.get(opts, :memory_id)
      query = Keyword.get(opts, :query)
      details = Keyword.get(opts, :details, %{})

      message =
        cond do
          query != nil ->
            "No memories found matching query: '#{query}'"

          memory_id != nil ->
            "Memory '#{memory_id}' not found"

          true ->
            "Memory not found"
        end

      %__MODULE__{
        message: message,
        memory_id: memory_id,
        query: query,
        details: details
      }
    end
  end

  defmodule MemoryStorageFailed do
    @moduledoc """
    Error raised when storing a memory entry fails.
    """
    defexception [:message, :reason, :content, :details]

    @impl true
    def exception(opts) do
      reason = Keyword.get(opts, :reason)
      content = Keyword.get(opts, :content)
      details = Keyword.get(opts, :details, %{})

      message =
        case reason do
          nil -> "Failed to store memory"
          r when is_binary(r) -> "Failed to store memory: #{r}"
          r -> "Failed to store memory: #{inspect(r)}"
        end

      %__MODULE__{
        message: message,
        reason: reason,
        content: content,
        details: details
      }
    end
  end

  defmodule MemoryPromotionFailed do
    @moduledoc """
    Error raised when promoting a memory to long-term storage fails.
    """
    defexception [:message, :memory_id, :reason, :details]

    @impl true
    def exception(opts) do
      memory_id = Keyword.get(opts, :memory_id)
      reason = Keyword.get(opts, :reason)
      details = Keyword.get(opts, :details, %{})

      message =
        case {memory_id, reason} do
          {nil, nil} -> "Failed to promote memory to long-term storage"
          {id, nil} -> "Failed to promote memory '#{id}' to long-term storage"
          {nil, r} -> "Failed to promote memory: #{inspect(r)}"
          {id, r} -> "Failed to promote memory '#{id}': #{inspect(r)}"
        end

      %__MODULE__{
        message: message,
        memory_id: memory_id,
        reason: reason,
        details: details
      }
    end
  end
end
