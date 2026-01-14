defmodule JidoCodeCore.APIConfigTest do
  use ExUnit.Case, async: false

  alias JidoCodeCore.API.Config, as: APIConfig
  alias JidoCodeCore.Settings

  @global_dir Path.join([System.user_home!(), ".jido_code"])
  @local_dir ".jido_code"

  setup do
    # Save original settings state
    original_env = System.get_env("JIDO_CODE_SETTINGS_DIR")

    # Create a temporary directory for test settings
    tmp_dir = Path.join(System.tmp_dir!(), "config_test_#{:rand.uniform(100_000)}")
    File.mkdir_p!(tmp_dir)

    # Set test settings directory
    System.put_env("JIDO_CODE_SETTINGS_DIR", tmp_dir)

    # Clear settings cache to ensure fresh state
    Settings.reload()

    on_exit(fn ->
      # Restore original environment
      if original_env do
        System.put_env("JIDO_CODE_SETTINGS_DIR", original_env)
      else
        System.delete_env("JIDO_CODE_SETTINGS_DIR")
      end

      # Clean up temp directory
      File.rm_rf!(tmp_dir)

      # Reload settings to restore original state
      Settings.reload()
    end)

    {:ok, %{tmp_dir: tmp_dir}}
  end

  describe "get_global_settings/0" do
    test "returns settings map" do
      assert {:ok, settings} = APIConfig.get_global_settings()

      assert is_map(settings)
    end
  end

  describe "get_setting/1" do
    test "returns nil for non-existent key" do
      assert is_nil(APIConfig.get_setting("nonexistent_key_xyz"))
    end
  end

  describe "get_setting/2" do
    test "returns default for non-existent key" do
      assert APIConfig.get_setting("nonexistent_key", "default_value") == "default_value"
    end

    test "works with different types of defaults" do
      assert APIConfig.get_setting("missing", "string") == "string"
      assert APIConfig.get_setting("missing", 123) == 123
      assert APIConfig.get_setting("missing", :atom) == :atom
      assert APIConfig.get_setting("missing", ["list"]) == ["list"]
    end
  end

  describe "reload_settings/0" do
    test "returns settings map" do
      assert {:ok, settings} = APIConfig.reload_settings()

      assert is_map(settings)
    end

    test "clears and reloads cache" do
      # Get initial settings
      {:ok, settings1} = APIConfig.get_global_settings()

      # Reload should still return valid settings
      {:ok, settings2} = APIConfig.reload_settings()

      assert is_map(settings2)
    end
  end

  describe "list_providers/0" do
    test "returns list of providers when configured" do
      # Note: This test assumes default configuration may or may not have providers
      # The function should return either {:ok, providers} or {:error, :not_found}

      result = APIConfig.list_providers()

      assert result == {:error, :not_found} or match?({:ok, _}, result)
    end
  end

  describe "list_models_for_provider/1" do
    test "returns error for non-existent provider" do
      assert {:error, :not_found} = APIConfig.list_models_for_provider("nonexistent_provider")
    end

    test "returns error for empty provider string" do
      assert {:error, :not_found} = APIConfig.list_models_for_provider("")
    end
  end

  describe "global_settings_path/0" do
    test "returns path to global settings file" do
      path = APIConfig.global_settings_path()

      assert is_binary(path)
      assert String.ends_with?(path, ".jido_code/settings.json")
    end

    test "path includes correct directory" do
      path = APIConfig.global_settings_path()

      assert String.contains?(path, @global_dir)
    end
  end

  describe "local_settings_path/0" do
    test "returns path to local settings file" do
      path = APIConfig.local_settings_path()

      assert is_binary(path)
      assert String.ends_with?(path, ".jido_code/settings.json")
    end

    test "path includes local directory name" do
      path = APIConfig.local_settings_path()

      assert String.contains?(path, @local_dir)
    end
  end

  describe "global_settings_dir/0" do
    test "returns path to global settings directory" do
      dir = APIConfig.global_settings_dir()

      assert is_binary(dir)
      assert String.ends_with?(dir, ".jido_code")
    end

    test "directory is within user home" do
      dir = APIConfig.global_settings_dir()

      assert String.contains?(dir, System.user_home!())
    end
  end

  describe "local_settings_dir/0" do
    test "returns path to local settings directory" do
      dir = APIConfig.local_settings_dir()

      assert is_binary(dir)
      assert String.ends_with?(dir, ".jido_code")
    end

    test "directory is relative to current directory" do
      dir = APIConfig.local_settings_dir()

      assert String.contains?(dir, @local_dir)
    end
  end
end
