defmodule JidoCodeCore.API.Config do
  @moduledoc """
  Public API for configuration management in JidoCodeCore.Core.

  This module provides the interface for accessing and modifying global
  and project-specific configuration settings.

  ## Settings Locations

  Settings are stored in two locations:

  - **Global**: `~/.jido_code/settings.json` - applies to all projects
  - **Local**: `./.jido_code/settings.json` - project-specific overrides

  Local settings override global settings. The merged result is what
  applications see when querying configuration.

  ## Settings Schema

  ```json
  {
    "version": 1,
    "provider": "anthropic",
    "model": "claude-3-5-sonnet-20241022",
    "providers": ["anthropic", "openai", "openrouter"],
    "models": {
      "anthropic": ["claude-3-5-sonnet-20241022", "claude-3-opus-20240229"],
      "openai": ["gpt-4o", "gpt-4-turbo"]
    }
  }
  ```

  All keys are optional. The `version` field enables future schema migrations.

  ## Examples

      # Get global settings
      {:ok, settings} = get_global_settings()
      settings["provider"]
      # => "anthropic"

      # Get a specific value
      provider = get_setting("provider", "openai")
      # => "anthropic"

      # List available providers
      {:ok, providers} = list_providers()
      # => [:anthropic, :openai, :openrouter]

      # Get models for a provider
      {:ok, models} = list_models_for_provider("anthropic")
      # => ["claude-3-5-sonnet-20241022", "claude-3-opus-20240229"]

  """

  alias JidoCodeCore.Settings

  @typedoc "Settings map structure"
  @type settings :: %{
    optional(String.t()) =>
      pos_integer() | String.t() | [String.t()] | %{optional(String.t()) => [String.t()]}
  }

  # ============================================================================
  # Settings Access
  # ============================================================================

  @doc """
  Gets the merged global and local settings.

  Settings are loaded with the following precedence:
  1. Local settings (`./.jido_code/settings.json`)
  2. Global settings (`~/.jido_code/settings.json`)

  Results are cached in memory. Use `reload_settings/0` to force a fresh load.

  ## Returns

    - `{:ok, settings}` - Merged settings map

  ## Examples

      {:ok, settings} = get_global_settings()
      settings["provider"]
      # => "anthropic"

  """
  @spec get_global_settings() :: {:ok, settings()}
  def get_global_settings do
    Settings.load()
  end

  @doc """
  Gets a single setting value by key.

  ## Parameters

    - `key` - The setting key (e.g., "provider", "model")

  ## Returns

    - The value if present
    - `nil` if the key doesn't exist

  ## Examples

      get_setting("provider")
      # => "anthropic"

      get_setting("nonexistent")
      # => nil

  """
  @spec get_setting(String.t()) :: term() | nil
  def get_setting(key) when is_binary(key) do
    Settings.get(key)
  end

  @doc """
  Gets a single setting value by key, with a default.

  ## Parameters

    - `key` - The setting key
    - `default` - Value to return if key doesn't exist

  ## Returns

    - The value if present
    - The default value if the key doesn't exist

  ## Examples

      get_setting("provider", "openai")
      # => "anthropic"

      get_setting("nonexistent", "default")
      # => "default"

  """
  @spec get_setting(String.t(), term()) :: term()
  def get_setting(key, default) when is_binary(key) do
    Settings.get(key, default)
  end

  @doc """
  Reloads settings from disk, clearing the cache.

  ## Returns

    - `{:ok, settings}` - Freshly loaded settings

  ## Examples

      {:ok, settings} = reload_settings()

  """
  @spec reload_settings() :: {:ok, settings()}
  def reload_settings do
    Settings.reload()
  end

  # ============================================================================
  # Provider and Model Listing
  # ============================================================================

  @doc """
  Lists available LLM providers from settings.

  ## Returns

    - `{:ok, providers}` - List of provider strings
    - `{:error, :not_found}` - No providers configured

  ## Examples

      {:ok, providers} = list_providers()
      # => {:ok, ["anthropic", "openai", "openrouter"]}

  """
  @spec list_providers() :: {:ok, [String.t()]} | {:error, :not_found}
  def list_providers do
    {:ok, settings} = get_global_settings()

    case Map.get(settings, "providers") do
      nil -> {:error, :not_found}
      providers when is_list(providers) -> {:ok, providers}
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Lists available models for a specific provider.

  ## Parameters

    - `provider` - Provider name (e.g., "anthropic", "openai")

  ## Returns

    - `{:ok, models}` - List of model identifiers
    - `{:error, :not_found}` - Provider not found or no models configured

  ## Examples

      {:ok, models} = list_models_for_provider("anthropic")
      # => {:ok, ["claude-3-5-sonnet-20241022", "claude-3-opus-20240229"]}

  """
  @spec list_models_for_provider(String.t()) :: {:ok, [String.t()]} | {:error, :not_found}
  def list_models_for_provider(provider) when is_binary(provider) do
    {:ok, settings} = get_global_settings()

    case Map.get(settings, "models") do
      nil ->
        {:error, :not_found}

      models when is_map(models) ->
        case Map.get(models, provider) do
          nil -> {:error, :not_found}
          model_list when is_list(model_list) -> {:ok, model_list}
          _ -> {:error, :not_found}
        end

      _ ->
        {:error, :not_found}
    end
  end

  # ============================================================================
  # Settings File Paths
  # ============================================================================

  @doc """
  Gets the path to the global settings file.

  ## Returns

    - Absolute path to `~/.jido_code/settings.json`

  ## Examples

      global_settings_path()
      # => "/home/user/.jido_code/settings.json"

  """
  @spec global_settings_path() :: String.t()
  def global_settings_path do
    Settings.global_path()
  end

  @doc """
  Gets the path to the local (project) settings file.

  ## Returns

    - Absolute path to `./.jido_code/settings.json`

  ## Examples

      local_settings_path()
      # => "/home/user/project/.jido_code/settings.json"

  """
  @spec local_settings_path() :: String.t()
  def local_settings_path do
    Settings.local_path()
  end

  @doc """
  Gets the global settings directory path.

  ## Returns

    - Absolute path to `~/.jido_code/`

  ## Examples

      global_settings_dir()
      # => "/home/user/.jido_code"

  """
  @spec global_settings_dir() :: String.t()
  def global_settings_dir do
    Settings.global_dir()
  end

  @doc """
  Gets the local (project) settings directory path.

  ## Returns

    - Absolute path to `./.jido_code/`

  ## Examples

      local_settings_dir()
      # => "/home/user/project/.jido_code"

  """
  @spec local_settings_dir() :: String.t()
  def local_settings_dir do
    Settings.local_dir()
  end

  # ============================================================================
  # Settings Validation
  # ============================================================================

  @doc """
  Validates a settings map against the expected schema.

  ## Parameters

    - `settings` - Settings map to validate

  ## Returns

    - `{:ok, settings}` - Valid settings
    - `{:error, reason}` - Validation error with message

  ## Examples

      {:ok, settings} = validate_settings(%{"provider" => "anthropic"})

      {:error, "provider must be a string, got: 123"} =
        validate_settings(%{"provider" => 123})

  """
  @spec validate_settings(map()) :: {:ok, settings()} | {:error, String.t()}
  def validate_settings(settings) when is_map(settings) do
    Settings.validate(settings)
  end

  # ============================================================================
  # Directory Management
  # ============================================================================

  @doc """
  Ensures the global settings directory exists.

  Creates `~/.jido_code/` if it doesn't exist.

  ## Returns

    - `:ok` - Directory exists or was created
    - `{:error, reason}` - Failed to create directory

  ## Examples

      :ok = ensure_global_settings_dir()

  """
  @spec ensure_global_settings_dir() :: :ok | {:error, term()}
  def ensure_global_settings_dir do
    Settings.ensure_global_dir()
  end

  @doc """
  Ensures the local settings directory exists.

  Creates `./.jido_code/` if it doesn't exist.

  ## Returns

    - `:ok` - Directory exists or was created
    - `{:error, reason}` - Failed to create directory

  ## Examples

      :ok = ensure_local_settings_dir()

  """
  @spec ensure_local_settings_dir() :: :ok | {:error, term()}
  def ensure_local_settings_dir do
    Settings.ensure_local_dir()
  end

  # ============================================================================
  # Schema Information
  # ============================================================================

  @doc """
  Returns the current settings schema version.

  This version number is incremented when breaking changes are made to the
  settings schema. It can be used for migration logic.

  ## Returns

    - Schema version number (positive integer)

  ## Examples

      settings_schema_version()
      # => 1

  """
  @spec settings_schema_version() :: pos_integer()
  def settings_schema_version do
    Settings.schema_version()
  end
end
