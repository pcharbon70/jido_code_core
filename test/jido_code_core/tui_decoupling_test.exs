defmodule JidoCodeCore.TUIDecouplingTest do
  @moduledoc """
  Tests to ensure JidoCodeCore is fully decoupled from TUI dependencies.

  These tests verify that the core library can operate independently
  without any references to TermUI or JidoCode.TUI.
  """

  use ExUnit.Case, async: true

  alias JidoCodeCore.Settings

  describe "Code Structure - No TUI References" do
    test "no TermUI references in core library source files" do
      # Scan all .ex files in lib/
      lib_path = Path.join([File.cwd!(), "lib", "jido_code_core"])

      lib_path
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.each(fn file_path ->
        file_content = File.read!(file_path)

        # Check for TermUI module references (case-insensitive)
        refute Regex.match?(~r/TermUI/i, file_content),
               "Found TermUI reference in #{Path.relative_to(file_path, lib_path)}"

        # Check for TUI module references
        refute String.contains?(file_content, "JidoCode.TUI"),
               "Found JidoCode.TUI reference in #{Path.relative_to(file_path, lib_path)}"
      end)
    end

    test "no TUI-specific data structures in API responses" do
      # API functions should return plain maps, strings, and tuples
      # not TUI-specific types like TermUI.View.t() or TermUI.Component.RenderNode.t()

      # Verify Settings API returns plain types
      assert {:ok, settings} = Settings.load()
      assert is_map(settings)

      assert is_binary(Settings.global_dir())
      assert is_binary(Settings.global_path())
      assert is_binary(Settings.local_dir())
      assert is_binary(Settings.local_path())
    end
  end

  describe "Error Messages - Plain Strings" do
    test "settings validation errors are plain strings" do
      # All error returns should be plain string tuples, not TUI-formatted
      assert {:error, msg} = Settings.validate(%{"invalid_key" => "value"})
      assert is_binary(msg)
      # No markdown code blocks
      refute String.contains?(msg, "```")
    end

    test "settings file errors are plain strings" do
      assert {:error, msg} = Settings.read_file("/nonexistent/path/settings.json")
      assert is_binary(msg) or msg == :not_found
    end
  end

  describe "Configuration - TUI Independent" do
    test "settings work without TUI values" do
      # Core should not require TUI-specific settings
      minimal_valid_settings = %{
        "provider" => "anthropic",
        "model" => "claude-3-5-sonnet"
      }

      assert {:ok, _settings} = Settings.validate(minimal_valid_settings)
    end

    test "theme setting is optional" do
      # Theme is TUI-specific but optional in Core
      without_theme = %{"provider" => "anthropic"}
      with_theme = %{"provider" => "anthropic", "theme" => "dark"}

      assert {:ok, _} = Settings.validate(without_theme)
      assert {:ok, _} = Settings.validate(with_theme)
    end

    test "all core settings work without TUI context" do
      # Verify core settings don't assume TUI presence
      core_settings = %{
        "version" => 1,
        "provider" => "anthropic",
        "model" => "claude-3-5-sonnet",
        "providers" => ["anthropic", "openai"],
        "models" => %{
          "anthropic" => ["claude-3-5-sonnet", "claude-3-opus"],
          "openai" => ["gpt-4o", "gpt-4-turbo"]
        }
      }

      assert {:ok, validated} = Settings.validate(core_settings)
      assert validated["provider"] == "anthropic"
      assert validated["model"] == "claude-3-5-sonnet"
    end
  end

  describe "Dependency Check" do
    test "mix.exs has no TermUI dependency" do
      mix_exs = File.read!(Path.join([File.cwd!(), "mix.exs"]))

      # TermUI should not be in dependencies
      refute String.contains?(mix_exs, ":termui") or
               String.contains?(mix_exs, "TermUI"),
             "mix.exs should not depend on TermUI"
    end

    test "application starts without TUI" do
      # Verify core application starts independently
      # This test runs in the test process which doesn't have TUI running
      assert Process.whereis(JidoCodeCore.PubSub) != nil
      assert Process.whereis(JidoCodeCore.Supervisor) != nil
    end
  end

  describe "PubSub Events - TUI Agnostic" do
    test "PubSub events don't require TUI subscribers" do
      # PubSub should work without any TUI subscribers
      topic = "test_topic"

      # Broadcast without subscribers
      Phoenix.PubSub.broadcast(JidoCodeCore.PubSub, topic, :test_message)

      # Should not raise any errors
      assert true
    end
  end
end
