defmodule JidoCodeCore.APIToolsTest do
  use ExUnit.Case, async: false

  alias JidoCodeCore.API.Tools, as: APITools
  alias JidoCodeCore.Tools.{Registry, Tool, Param}

  # Dummy handler modules for testing
  defmodule ReadFileHandler do
    def execute(_params, _context), do: {:ok, "file contents"}
  end

  defmodule WriteFileHandler do
    def execute(_params, _context), do: {:ok, "written"}
  end

  defmodule GrepHandler do
    def execute(_params, _context), do: {:ok, "grep results"}
  end

  @test_tools [
    Tool.new!(%{
      name: "read_file",
      description: "Reads a file's contents",
      handler: ReadFileHandler,
      parameters: [
        Param.new!(%{name: "path", type: :string, description: "File path", required: true})
      ]
    }),
    Tool.new!(%{
      name: "write_file",
      description: "Writes content to a file",
      handler: WriteFileHandler,
      parameters: [
        Param.new!(%{name: "path", type: :string, description: "File path", required: true}),
        Param.new!(%{name: "content", type: :string, description: "File content", required: true})
      ]
    }),
    Tool.new!(%{
      name: "grep",
      description: "Searches file contents",
      handler: GrepHandler,
      parameters: [
        Param.new!(%{name: "pattern", type: :string, description: "Search pattern", required: true}),
        Param.new!(%{name: "path", type: :string, description: "File path", required: true})
      ]
    })
  ]

  setup do
    # Clear any existing tools
    Registry.clear()

    # Register test tools
    Enum.each(@test_tools, fn tool ->
      :ok = Registry.register(tool)
    end)

    on_exit(fn ->
      Registry.clear()
    end)

    :ok
  end

  describe "list_tools/0" do
    test "returns a list of tools" do
      tools = APITools.list_tools()

      assert is_list(tools)
      assert length(tools) > 0
    end

    test "returns Tool structs with required fields" do
      tools = APITools.list_tools()

      Enum.each(tools, fn tool ->
        assert %Tool{} = tool
        assert is_binary(tool.name)
        assert is_binary(tool.description)
        assert is_list(tool.parameters)
      end)
    end

    test "tools are sorted alphabetically by name" do
      tools = APITools.list_tools()

      tool_names = Enum.map(tools, & &1.name)
      assert tool_names == Enum.sort(tool_names)
    end

    test "includes expected core tools" do
      tools = APITools.list_tools()
      tool_names = Enum.map(tools, & &1.name)

      # Check for some expected tools
      assert "read_file" in tool_names
      assert "write_file" in tool_names
      assert "grep" in tool_names
    end
  end

  describe "get_tool_schema/1" do
    test "returns tool for registered tool" do
      assert {:ok, tool} = APITools.get_tool_schema("read_file")

      assert tool.name == "read_file"
      assert is_binary(tool.description)
      assert is_list(tool.parameters)
    end

    test "returns error for non-existent tool" do
      assert {:error, :not_found} = APITools.get_tool_schema("nonexistent_tool")
    end

    test "tool has expected parameter structure" do
      {:ok, tool} = APITools.get_tool_schema("read_file")

      Enum.each(tool.parameters, fn param ->
        assert Map.has_key?(param, :name)
        assert Map.has_key?(param, :type)
      end)
    end
  end

  describe "tool_registered?/1" do
    test "returns true for registered tools" do
      assert APITools.tool_registered?("read_file")
      assert APITools.tool_registered?("write_file")
      assert APITools.tool_registered?("grep")
    end

    test "returns false for non-existent tools" do
      refute APITools.tool_registered?("nonexistent_tool")
      refute APITools.tool_registered?("")
    end
  end

  describe "count_tools/0" do
    test "returns positive number of tools" do
      count = APITools.count_tools()

      assert is_integer(count)
      assert count > 0
    end

    test "count matches list_tools length" do
      count = APITools.count_tools()
      tools = APITools.list_tools()

      assert count == length(tools)
    end
  end

  describe "tools_for_llm/0" do
    test "returns list of tool definitions" do
      tools = APITools.tools_for_llm()

      assert is_list(tools)
      assert length(tools) > 0
    end

    test "each tool has LLM-compatible format" do
      tools = APITools.tools_for_llm()

      Enum.each(tools, fn tool ->
        assert Map.has_key?(tool, :type)
        assert Map.has_key?(tool, :function)
        assert tool.type == "function"
        assert is_map(tool.function)
      end)
    end

    test "tool function has required keys" do
      tools = APITools.tools_for_llm()

      Enum.each(tools, fn tool ->
        func = tool.function

        assert Map.has_key?(func, :name)
        assert Map.has_key?(func, :description)
        assert Map.has_key?(func, :parameters)
      end)
    end
  end

  describe "describe_tools/0" do
    test "returns string description" do
      description = APITools.describe_tools()

      assert is_binary(description)
      assert String.length(description) > 0
    end

    test "description includes tool names" do
      description = APITools.describe_tools()

      assert String.contains?(description, "read_file")
      assert String.contains?(description, "write_file")
    end

    test "description is formatted with sections" do
      description = APITools.describe_tools()

      # Should have markdown-style headers
      assert String.contains?(description, "##")
    end
  end

  describe "parse_llm_tool_calls/1" do
    test "parses valid tool call response" do
      response = %{
        "tool_calls" => [
          %{
            "id" => "call_123",
            "type" => "function",
            "function" => %{
              "name" => "read_file",
              "arguments" => "{\"path\": \"/test.ex\"}"
            }
          }
        ]
      }

      assert {:ok, calls} = APITools.parse_llm_tool_calls(response)
      assert is_list(calls)
      assert length(calls) == 1

      call = Enum.at(calls, 0)
      assert call.id == "call_123"
      assert call.name == "read_file"
      assert call.arguments == %{"path" => "/test.ex"}
    end

    test "returns error when no tool_calls key" do
      response = %{"content" => "Just text"}

      assert {:error, :no_tool_calls} = APITools.parse_llm_tool_calls(response)
    end

    test "returns error when tool_calls is empty" do
      response = %{"tool_calls" => []}

      assert {:error, :no_tool_calls} = APITools.parse_llm_tool_calls(response)
    end

    test "parses multiple tool calls" do
      response = %{
        "tool_calls" => [
          %{
            "id" => "call_1",
            "type" => "function",
            "function" => %{
              "name" => "read_file",
              "arguments" => "{\"path\": \"/a.ex\"}"
            }
          },
          %{
            "id" => "call_2",
            "type" => "function",
            "function" => %{
              "name" => "write_file",
              "arguments" => "{\"path\": \"/b.ex\", \"content\": \"test\"}"
            }
          }
        ]
      }

      assert {:ok, calls} = APITools.parse_llm_tool_calls(response)
      assert length(calls) == 2
    end
  end

  describe "execute_tool/4" do
    test "requires valid session_id" do
      # Note: Actual execution tests require more setup
      # These tests verify the API structure
      assert is_function(&APITools.execute_tool/4)
    end

    test "requires tool_name string" do
      assert_raise FunctionClauseError, fn ->
        APITools.execute_tool("session-id", :invalid, %{})
      end
    end

    test "requires arguments map" do
      assert_raise FunctionClauseError, fn ->
        APITools.execute_tool("session-id", "read_file", "invalid")
      end
    end
  end
end
