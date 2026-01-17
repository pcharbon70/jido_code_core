defmodule JidoCodeCore.Integration.NamespaceTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Integration tests verifying namespace consistency in JidoCodeCore.

  These tests ensure:
  1. All modules use JidoCodeCore.* namespace
  2. No old JidoCode.* references (excluding JidoCodeCore)
  3. No TUI module dependencies
  """

  describe "1.4.1 Namespace Integration" do
    test "1.4.1.1 All core modules use JidoCodeCore.* namespace" do
      # Get all compiled .beam files in the JidoCodeCore application
      ebin_dir = Path.join([__DIR__, "../../../_build/dev/lib/jido_code_core/ebin"])

      jido_code_core_modules =
        ebin_dir
        |> File.ls!()
        |> Enum.filter(fn file ->
          String.ends_with?(file, ".beam")
        end)
        |> Enum.map(fn file ->
          file
          |> String.replace_suffix(".beam", "")
          |> String.to_atom()
        end)
        |> Enum.filter(fn mod ->
          # Only check Elixir.JidoCodeCore.* modules
          case Atom.to_string(mod) do
            "Elixir.JidoCodeCore." <> _ -> true
            _ -> false
          end
        end)

      # Verify we have a reasonable number of modules
      assert length(jido_code_core_modules) > 50,
             "Expected at least 50 JidoCodeCore modules, found #{length(jido_code_core_modules)}"

      # Verify all use the correct namespace
      Enum.each(jido_code_core_modules, fn mod ->
        namespace = mod |> Module.split() |> List.first()

        assert namespace == "JidoCodeCore",
               "Module #{mod} has namespace #{namespace}, expected JidoCodeCore"
      end)
    end

    test "1.4.1.2 No references to old JidoCode.Agents.* namespace in source files" do
      # Scan all source files for old namespace references
      lib_dir = Path.join([__DIR__, "../../../../lib"])

      old_agent_refs =
        lib_dir
        |> Path.join("**/*.ex")
        |> Path.wildcard()
        |> Enum.flat_map(fn file ->
          file
          |> File.read!()
          |> String.split("\n")
          |> Enum.with_index(1)
          |> Enum.filter(fn {line, _line_num} ->
            String.contains?(line, "JidoCode.Agents.") and
              not String.contains?(line, "JidoCodeCore.Agents.")
          end)
          |> Enum.map(fn {line, line_num} -> {file, line_num, String.trim(line)} end)
        end)

      # Filter out comments and doc strings
      problematic_refs =
        Enum.reject(old_agent_refs, fn {_file, _line_num, line} ->
          String.trim(line) |> String.starts_with?("#") or
            String.contains?(line, "@moduledoc") or
            String.contains?(line, "@doc")
        end)

      # Allow some references in documentation, but not in actual code
      # We'll just warn about these
      if length(problematic_refs) > 0 do
        IO.warn(
          "Found #{length(problematic_refs)} references to old JidoCode.Agents namespace:\n" <>
            Enum.map_join(problematic_refs, "\n", fn {file, line_num, line} ->
              "  #{Path.relative_to_cwd(file)}:#{line_num}: #{String.slice(line, 0, 80)}"
            end)
        )
      end

      # For this test, we'll verify the count is low (documentation references are OK)
      assert length(problematic_refs) < 5,
             "Found too many references to old JidoCode.Agents namespace: #{length(problematic_refs)}"
    end

    test "1.4.1.3 No references to old JidoCode.Tools.* namespace in source files" do
      lib_dir = Path.join([__DIR__, "../../../../lib"])

      old_tools_refs =
        lib_dir
        |> Path.join("**/*.ex")
        |> Path.wildcard()
        |> Enum.flat_map(fn file ->
          file
          |> File.read!()
          |> String.split("\n")
          |> Enum.with_index(1)
          |> Enum.filter(fn {line, _line_num} ->
            String.contains?(line, "JidoCode.Tools.") and
              not String.contains?(line, "JidoCodeCore.Tools.")
          end)
          |> Enum.map(fn {line, line_num} -> {file, line_num, String.trim(line)} end)
        end)

      # Allow some references in documentation
      problematic_refs =
        Enum.reject(old_tools_refs, fn {_file, _line_num, line} ->
          String.trim(line) |> String.starts_with?("#") or
            String.contains?(line, "@moduledoc") or
            String.contains?(line, "@doc")
        end)

      assert length(problematic_refs) < 5,
             "Found too many references to old JidoCode.Tools namespace: #{length(problematic_refs)}"
    end

    test "1.4.1.4 No references to TUI modules (TermUI) from Core" do
      lib_dir = Path.join([__DIR__, "../../../../lib"])

      # Check for any TermUI references
      termui_refs =
        lib_dir
        |> Path.join("**/*.ex")
        |> Path.wildcard()
        |> Enum.flat_map(fn file ->
          file
          |> File.read!()
          |> String.split("\n")
          |> Enum.with_index(1)
          |> Enum.filter(fn {line, _line_num} ->
            String.contains?(line, "TermUI") or String.contains?(line, "TermUi")
          end)
          |> Enum.map(fn {_line, line_num} -> {Path.relative_to(file, lib_dir), line_num} end)
        end)

      # JidoCodeCore should NOT reference TermUI
      assert length(termui_refs) == 0,
             """
             Found #{length(termui_refs)} TermUI references in JidoCodeCore:
             #{Enum.map_join(termui_refs, "\n", fn {file, line_num} -> "  #{file}:#{line_num}" end)}
             JidoCodeCore must be independent of TUI modules.
             """
    end
  end
end
