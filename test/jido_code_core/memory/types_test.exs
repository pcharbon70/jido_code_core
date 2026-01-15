defmodule JidoCodeCore.Memory.TypesTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Memory.Types

  doctest Types

  describe "confidence_to_level/1" do
    test "returns :high for confidence >= 0.8" do
      assert Types.confidence_to_level(0.8) == :high
      assert Types.confidence_to_level(0.9) == :high
      assert Types.confidence_to_level(1.0) == :high
    end

    test "returns :medium for confidence >= 0.5 and < 0.8" do
      assert Types.confidence_to_level(0.5) == :medium
      assert Types.confidence_to_level(0.6) == :medium
      assert Types.confidence_to_level(0.7) == :medium
      assert Types.confidence_to_level(0.79) == :medium
    end

    test "returns :low for confidence < 0.5" do
      assert Types.confidence_to_level(0.0) == :low
      assert Types.confidence_to_level(0.1) == :low
      assert Types.confidence_to_level(0.3) == :low
      assert Types.confidence_to_level(0.49) == :low
    end
  end

  describe "level_to_confidence/1" do
    test "returns 0.9 for :high" do
      assert Types.level_to_confidence(:high) == 0.9
    end

    test "returns 0.6 for :medium" do
      assert Types.level_to_confidence(:medium) == 0.6
    end

    test "returns 0.3 for :low" do
      assert Types.level_to_confidence(:low) == 0.3
    end
  end

  describe "memory type lists" do
    test "memory_types/0 returns all valid memory types" do
      types = Types.memory_types()

      assert :fact in types
      assert :assumption in types
      assert :hypothesis in types
      assert :discovery in types
      assert :risk in types
      assert :unknown in types
      assert :decision in types
      assert :convention in types
      assert :error in types
      assert :bug in types
    end

    test "knowledge_types/0 returns knowledge types" do
      types = Types.knowledge_types()

      assert types == [:fact, :assumption, :hypothesis, :discovery, :risk, :unknown]
    end

    test "decision_types/0 returns decision types" do
      types = Types.decision_types()

      assert :decision in types
      assert :architectural_decision in types
      assert :implementation_decision in types
      assert :alternative in types
      assert :trade_off in types
    end

    test "convention_types/0 returns convention types" do
      types = Types.convention_types()

      assert :convention in types
      assert :coding_standard in types
      assert :architectural_convention in types
      assert :agent_rule in types
      assert :process_convention in types
    end

    test "error_memory_types/0 returns error types" do
      types = Types.error_memory_types()

      assert types == [:error, :bug, :failure, :incident, :root_cause, :lesson_learned]
    end
  end

  describe "type validation functions" do
    test "valid_memory_type?/1 checks validity" do
      assert Types.valid_memory_type?(:fact)
      assert Types.valid_memory_type?(:assumption)
      assert Types.valid_memory_type?(:decision)
      assert Types.valid_memory_type?(:convention)
      assert Types.valid_memory_type?(:bug)

      refute Types.valid_memory_type?(:invalid)
      refute Types.valid_memory_type?(:random)
      refute Types.valid_memory_type?(nil)
      refute Types.valid_memory_type?("fact")
      refute Types.valid_memory_type?(123)
    end

    test "valid_confidence_level?/1 checks validity" do
      assert Types.valid_confidence_level?(:high)
      assert Types.valid_confidence_level?(:medium)
      assert Types.valid_confidence_level?(:low)

      refute Types.valid_confidence_level?(:invalid)
      refute Types.valid_confidence_level?(nil)
    end

    test "valid_source_type?/1 checks validity" do
      assert Types.valid_source_type?(:user)
      assert Types.valid_source_type?(:agent)
      assert Types.valid_source_type?(:tool)
      assert Types.valid_source_type?(:external_document)

      refute Types.valid_source_type?(:invalid)
      refute Types.valid_source_type?(nil)
    end

    test "valid_context_key?/1 checks validity" do
      valid_keys = [
        :active_file,
        :project_root,
        :primary_language,
        :framework,
        :current_task,
        :user_intent,
        :discovered_patterns,
        :active_errors,
        :pending_questions,
        :file_relationships,
        :conversation_summary
      ]

      Enum.each(valid_keys, fn key ->
        assert Types.valid_context_key?(key)
      end)

      refute Types.valid_context_key?(:invalid_key)
      refute Types.valid_context_key?(nil)
      refute Types.valid_context_key?("active_file")
    end

    test "valid_relationship?/1 checks validity" do
      assert Types.valid_relationship?(:refines)
      assert Types.valid_relationship?(:confirms)
      assert Types.valid_relationship?(:contradicts)
      assert Types.valid_relationship?(:has_alternative)
      assert Types.valid_relationship?(:justified_by)

      refute Types.valid_relationship?(:invalid)
      refute Types.valid_relationship?(nil)
    end
  end

  describe "type category checks" do
    test "knowledge_type?/1 identifies knowledge types" do
      assert Types.knowledge_type?(:fact)
      assert Types.knowledge_type?(:assumption)
      assert Types.knowledge_type?(:hypothesis)
      assert Types.knowledge_type?(:discovery)

      refute Types.knowledge_type?(:decision)
      refute Types.knowledge_type?(:convention)
      refute Types.knowledge_type?(:bug)
    end

    test "decision_type?/1 identifies decision types" do
      assert Types.decision_type?(:decision)
      assert Types.decision_type?(:architectural_decision)
      assert Types.decision_type?(:alternative)

      refute Types.decision_type?(:fact)
      refute Types.decision_type?(:convention)
    end

    test "convention_type?/1 identifies convention types" do
      assert Types.convention_type?(:convention)
      assert Types.convention_type?(:coding_standard)
      assert Types.convention_type?(:agent_rule)

      refute Types.convention_type?(:fact)
      refute Types.convention_type?(:decision)
    end

    test "error_type?/1 identifies error types" do
      assert Types.error_type?(:error)
      assert Types.error_type?(:bug)
      assert Types.error_type?(:incident)
      assert Types.error_type?(:lesson_learned)

      refute Types.error_type?(:fact)
      refute Types.error_type?(:decision)
    end
  end

  describe "session ID validation" do
    test "valid_session_id?/1 accepts valid IDs" do
      assert Types.valid_session_id?("session-123")
      assert Types.valid_session_id?("my_session_456")
      assert Types.valid_session_id?("Session123")
      assert Types.valid_session_id?("test-session-123")
    end

    test "valid_session_id?/1 rejects invalid IDs" do
      refute Types.valid_session_id?("")
      refute Types.valid_session_id?("../../../etc/passwd")
      refute Types.valid_session_id?("session with spaces")
      refute Types.valid_session_id?("session.dot")
      refute Types.valid_session_id?(nil)
      refute Types.valid_session_id?(123)
    end

    test "valid_session_id?/1 rejects path traversal attempts" do
      refute Types.valid_session_id?("../escape")
      refute Types.valid_session_id?("../../../etc/passwd")
      refute Types.valid_session_id?("..\\..\\windows")
    end
  end

  describe "constants" do
    test "max_session_id_length/0 returns maximum length" do
      assert is_integer(Types.max_session_id_length())
      assert Types.max_session_id_length() == 128
    end

    test "default_max_memories_per_session/0 returns limit" do
      assert is_integer(Types.default_max_memories_per_session())
      assert Types.default_max_memories_per_session() == 10_000
    end

    test "default_promotion_threshold/0 returns threshold" do
      assert is_float(Types.default_promotion_threshold())
      assert Types.default_promotion_threshold() == 0.6
    end

    test "default_max_promotions_per_run/0 returns limit" do
      assert is_integer(Types.default_max_promotions_per_run())
      assert Types.default_max_promotions_per_run() == 20
    end
  end

  describe "clamp_to_unit/1" do
    test "clamps negative values to 0.0" do
      assert Types.clamp_to_unit(-0.5) == 0.0
      assert Types.clamp_to_unit(-1.0) == 0.0
      assert Types.clamp_to_unit(-100) == 0.0
    end

    test "clamps values above 1.0 to 1.0" do
      assert Types.clamp_to_unit(1.5) == 1.0
      assert Types.clamp_to_unit(2.0) == 1.0
      assert Types.clamp_to_unit(100) == 1.0
    end

    test "returns values within range unchanged" do
      assert Types.clamp_to_unit(0.0) == 0.0
      assert Types.clamp_to_unit(0.5) == 0.5
      assert Types.clamp_to_unit(1.0) == 1.0
    end

    test "handles integer input" do
      assert Types.clamp_to_unit(0) == 0.0
      assert Types.clamp_to_unit(1) == 1.0
    end

    test "handles float input" do
      assert Types.clamp_to_unit(0.3) == 0.3
      assert Types.clamp_to_unit(0.7) == 0.7
    end
  end

  describe "summary_cache_key/0" do
    test "returns :conversation_summary atom" do
      assert Types.summary_cache_key() == :conversation_summary
    end
  end

  describe "other getter functions" do
    test "confidence_levels/0 returns all levels" do
      assert Types.confidence_levels() == [:high, :medium, :low]
    end

    test "source_types/0 returns all source types" do
      assert Types.source_types() == [:user, :agent, :tool, :external_document]
    end

    test "context_keys/0 returns all context keys" do
      keys = Types.context_keys()
      assert :active_file in keys
      assert :project_root in keys
      assert :conversation_summary in keys
    end

    test "relationships/0 returns all relationships" do
      rels = Types.relationships()
      assert :refines in rels
      assert :confirms in rels
      assert :contradicts in rels
      assert :has_alternative in rels
    end

    test "convention_scopes/0 returns all scopes" do
      assert Types.convention_scopes() == [:global, :project, :agent]
    end

    test "enforcement_levels/0 returns all levels" do
      assert Types.enforcement_levels() == [:advisory, :required, :strict]
    end

    test "error_statuses/0 returns all statuses" do
      assert Types.error_statuses() == [:reported, :investigating, :resolved, :deferred]
    end

    test "evidence_strengths/0 returns all strengths" do
      assert Types.evidence_strengths() == [:weak, :moderate, :strong]
    end
  end
end
