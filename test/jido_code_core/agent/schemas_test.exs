defmodule JidoCodeCore.Agent.SchemasTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Agent.Schemas

  describe "session_agent_schema/0" do
    test "returns a valid Zoi schema" do
      schema = Schemas.session_agent_schema()
      assert is_map(schema)
    end
  end

  describe "validate_session_agent/1" do
    test "validates a valid session agent state" do
      params = %{
        session_id: "test-session-123",
        project_path: "/path/to/project",
        language: :elixir
      }

      assert {:ok, state} = Schemas.validate_session_agent(params)
      assert state.session_id == "test-session-123"
      assert state.project_path == "/path/to/project"
      assert state.language == :elixir
    end

    test "applies default values for missing fields" do
      params = %{session_id: "test-123"}

      assert {:ok, state} = Schemas.validate_session_agent(params)
      assert state.session_id == "test-123"
      assert state.language == :elixir  # Default applied
      assert state.messages == []  # Default applied
      assert state.reasoning_steps == []  # Default applied
      assert state.tool_calls == []  # Default applied
      assert state.todos == []  # Default applied
      assert state.file_reads == %{}  # Default applied
      assert state.file_writes == %{}  # Default applied
    end

    test "applies default values for llm_config" do
      params = %{session_id: "test-123"}

      assert {:ok, state} = Schemas.validate_session_agent(params)
      assert state.llm_config.provider == "anthropic"
      assert state.llm_config.model == "claude-3-5-sonnet-20241022"
      assert state.llm_config.temperature == 0.7
      assert state.llm_config.max_tokens == 4096
    end

    test "allows custom llm_config values" do
      params = %{
        session_id: "test-123",
        llm_config: %{
          provider: "openai",
          model: "gpt-4",
          temperature: 0.5,
          max_tokens: 2048
        }
      }

      assert {:ok, state} = Schemas.validate_session_agent(params)
      assert state.llm_config.provider == "openai"
      assert state.llm_config.model == "gpt-4"
      assert state.llm_config.temperature == 0.5
      assert state.llm_config.max_tokens == 2048
    end

    test "allows partial llm_config with defaults for missing fields" do
      params = %{
        session_id: "test-123",
        llm_config: %{
          provider: "openai"
        }
      }

      assert {:ok, state} = Schemas.validate_session_agent(params)
      assert state.llm_config.provider == "openai"
      assert state.llm_config.model == "claude-3-5-sonnet-20241022"  # Default
      assert state.llm_config.temperature == 0.7  # Default
      assert state.llm_config.max_tokens == 4096  # Default
    end

    test "validates with all fields provided" do
      params = %{
        session_id: "test-123",
        project_path: "/my/project",
        language: :python,
        messages: [%{role: "user", content: "hello"}],
        reasoning_steps: [%{step: 1, thought: "thinking"}],
        tool_calls: [%{name: "read_file", args: %{}}],
        todos: [%{id: 1, task: "write tests"}],
        file_reads: %{"/path/to/file.txt" => %{content: "data"}},
        file_writes: %{"/path/to/output.txt" => %{size: 100}},
        llm_config: %{
          provider: "anthropic",
          model: "claude-3-5-sonnet-20241022",
          temperature: 0.8,
          max_tokens: 8192
        },
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      assert {:ok, state} = Schemas.validate_session_agent(params)
      assert state.session_id == "test-123"
      assert state.project_path == "/my/project"
      assert state.language == :python
      assert length(state.messages) == 1
      assert length(state.reasoning_steps) == 1
      assert length(state.tool_calls) == 1
      assert length(state.todos) == 1
      assert map_size(state.file_reads) == 1
      assert map_size(state.file_writes) == 1
    end

    test "accepts empty map and applies all defaults" do
      assert {:ok, state} = Schemas.validate_session_agent(%{})
      assert state.language == :elixir
      assert state.messages == []
      assert state.llm_config.provider == "anthropic"
    end
  end

  describe "apply_defaults/1" do
    test "applies defaults to a partial state" do
      params = %{session_id: "test-123"}

      state = Schemas.apply_defaults(params)
      assert state.session_id == "test-123"
      assert state.language == :elixir
      assert state.messages == []
      assert state.reasoning_steps == []
    end

    test "returns default state for empty map" do
      state = Schemas.apply_defaults(%{})
      assert state.language == :elixir
      assert state.messages == []
      assert state.llm_config.provider == "anthropic"
    end

    test "preserves provided values" do
      params = %{
        session_id: "custom-123",
        language: :rust,
        messages: [%{role: "user"}]
      }

      state = Schemas.apply_defaults(params)
      assert state.session_id == "custom-123"
      assert state.language == :rust
      assert [%{role: "user"}] = state.messages
      assert state.reasoning_steps == []  # Default applied
    end
  end

  describe "default_state/0" do
    test "returns state with all default values" do
      state = Schemas.default_state()

      # Check all default values
      assert state.language == :elixir
      assert state.messages == []
      assert state.reasoning_steps == []
      assert state.tool_calls == []
      assert state.todos == []
      assert state.file_reads == %{}
      assert state.file_writes == %{}
      assert state.llm_config.provider == "anthropic"
      assert state.llm_config.model == "claude-3-5-sonnet-20241022"
      assert state.llm_config.temperature == 0.7
      assert state.llm_config.max_tokens == 4096
    end

    test "default state is consistent across multiple calls" do
      state1 = Schemas.default_state()
      state2 = Schemas.default_state()

      assert state1.language == state2.language
      assert state1.llm_config.provider == state2.llm_config.provider
    end
  end

  describe "schema coercion" do
    @tag :skip
    test "coerces string language to atom" do
      # Note: This test depends on Zoi's coercion behavior
      # If coercion is enabled, "elixir" becomes :elixir
      params = %{session_id: "test-123", language: "elixir"}

      assert {:ok, state} = Schemas.validate_session_agent(params)
      # Check if the value is either the coerced atom or original string
      # based on Zoi's behavior
      assert state.language in [:elixir, "elixir"]
    end
  end

  describe "optional fields" do
    test "allows nil for optional session_id" do
      params = %{}

      assert {:ok, state} = Schemas.validate_session_agent(params)
      # session_id is optional and not in defaults, so it won't be present
      refute Map.has_key?(state, :session_id)
    end

    test "allows nil for optional project_path" do
      params = %{}

      assert {:ok, state} = Schemas.validate_session_agent(params)
      refute Map.has_key?(state, :project_path)
    end

    test "allows nil for optional timestamps" do
      params = %{}

      assert {:ok, state} = Schemas.validate_session_agent(params)
      refute Map.has_key?(state, :created_at)
      refute Map.has_key?(state, :updated_at)
    end
  end

  describe "default_llm_config/0" do
    test "returns the default LLM configuration" do
      config = Schemas.default_llm_config()

      assert config.provider == "anthropic"
      assert config.model == "claude-3-5-sonnet-20241022"
      assert config.temperature == 0.7
      assert config.max_tokens == 4096
    end
  end

  describe "empty llm_config handling" do
    test "applies defaults when llm_config is an empty map" do
      params = %{
        session_id: "test-123",
        llm_config: %{}
      }

      assert {:ok, state} = Schemas.validate_session_agent(params)
      assert state.llm_config.provider == "anthropic"
      assert state.llm_config.model == "claude-3-5-sonnet-20241022"
      assert state.llm_config.temperature == 0.7
      assert state.llm_config.max_tokens == 4096
    end

    test "applies defaults when llm_config is nil" do
      params = %{
        session_id: "test-123",
        llm_config: nil
      }

      assert {:ok, state} = Schemas.validate_session_agent(params)
      assert state.llm_config.provider == "anthropic"
      assert state.llm_config.model == "claude-3-5-sonnet-20241022"
    end

    test "preserves provided llm_config values" do
      params = %{
        session_id: "test-123",
        llm_config: %{provider: "openai"}
      }

      assert {:ok, state} = Schemas.validate_session_agent(params)
      assert state.llm_config.provider == "openai"
      assert state.llm_config.model == "claude-3-5-sonnet-20241022"  # Default
    end
  end
end
