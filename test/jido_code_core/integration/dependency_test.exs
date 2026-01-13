defmodule JidoCodeCore.Integration.DependencyTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Integration tests verifying JidoCodeCore has no TUI dependencies.

  These tests ensure:
  1. Mix.exs has no termui dependency
  2. No imports of TUI modules in source
  3. Core compiles without TermUI
  """

  describe "1.4.4 Dependency Verification" do
    test "1.4.4.1 Mix deps tree shows no termui dependency" do
      # Read mix.exs to verify no termui dependency
      mix_exs_path = Path.join(__DIR__, "../../../mix.exs")

      mix_exs_content = File.read!(mix_exs_path)

      # Verify no termui in dependencies
      refute String.contains?(mix_exs_content, ":termui"),
             "mix.exs should not contain :termui dependency"

      # Verify no TermUI string (case insensitive)
      refute String.match?(mix_exs_content, ~r/[Tt]erm[Uu][Ii]/),
             "mix.exs should not contain TermUI dependency"
    end

    test "1.4.4.2 No imports of TUI modules compile" do
      lib_dir = Path.join([__DIR__, "../../../lib"])

      # Scan all source files for TUI imports
      tui_imports =
        lib_dir
        |> Path.join("**/*.ex")
        |> Path.wildcard()
        |> Enum.flat_map(fn file ->
          file
          |> File.read!()
          |> String.split("\n")
          |> Enum.with_index(1)
          |> Enum.filter(fn {line, _line_num} ->
            # Check for various TUI import patterns
            String.contains?(line, "import TermUI") or
              String.contains?(line, "use TermUI") or
              String.contains?(line, "alias TermUI") or
              String.contains?(line, "alias TermUi")
          end)
          |> Enum.map(fn {line, line_num} -> {Path.relative_to(file, lib_dir), line_num, line} end)
        end)

      # Should have no TUI imports
      assert length(tui_imports) == 0,
             """
             Found #{length(tui_imports)} TUI imports in JidoCodeCore:
             #{Enum.map_join(tui_imports, "\n", fn {file, line_num, line} ->
               "  #{file}:#{line_num}: #{String.trim(line)}"
             end)}
             JidoCodeCore must not import TUI modules.
             """
    end

    test "1.4.4.3 Core compiles without TermUI" do
      # This test passes if the test suite runs at all
      # The fact that we're executing this test means Core compiled
      # without TermUI being available

      # Double-check by verifying we can't access TermUI modules
      refute Code.ensure_loaded?(TermUI),
             "TermUI should not be loaded in JidoCodeCore tests"

      refute Code.ensure_loaded?(TermUi),
             "TermUi should not be loaded in JidoCodeCore tests"
    end

    test "1.4.4.4 Core has correct runtime dependencies" do
      # Verify by checking that our application doesn't start TUI processes
      # We can't directly inspect children, but we can verify the application starts
      # without starting TermUI

      assert {:ok, _} = Application.ensure_all_started(:jido_code_core)

      # Verify TermUI is not in the code path
      {:module, _} = Code.ensure_loaded(JidoCodeCore.Application)

      # If we got here without loading TermUI, we're good
      refute Code.ensure_loaded?(TermUI)
    end
  end
end
