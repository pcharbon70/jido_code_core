defmodule JidoCodeCore.Tools.ExecutorTest do
  use ExUnit.Case, async: false

  alias JidoCodeCore.Tools.{Executor, Registry, Result, Tool, Param}

  # Mock handler for testing
  defmodule MockHandler do
    def execute(%{"path" => path}, _context) do
      {:ok, "Contents of #{path}"}
    end

    def execute(%{"error" => true}, _context) do
      {:error, "Intentional error"}
    end

    def execute(%{"slow" => ms}, _context) do
      Process.sleep(ms)
      {:ok, "Completed after #{ms}ms"}
    end

    def execute(args, _context) do
      {:ok, "Executed with: #{inspect(args)}"}
    end
  end

  setup do
    # Clear registry for each test
    Registry.clear()

    # Register test tools
    read_file =
      Tool.new!(%{
        name: "read_file",
        description: "Read a file",
        handler: MockHandler,
        parameters: [
          Param.new!(%{name: "path", type: :string, description: "File path", required: true})
        ]
      })

    write_file =
      Tool.new!(%{
        name: "write_file",
        description: "Write a file",
        handler: MockHandler,
        parameters: [
          Param.new!(%{name: "path", type: :string, description: "File path", required: true}),
          Param.new!(%{name: "content", type: :string, description: "Content", required: true})
        ]
      })

    error_tool =
      Tool.new!(%{
        name: "error_tool",
        description: "Tool that errors",
        handler: MockHandler,
        parameters: [
          Param.new!(%{name: "error", type: :boolean, description: "Error flag", required: true})
        ]
      })

    slow_tool =
      Tool.new!(%{
        name: "slow_tool",
        description: "Slow tool",
        handler: MockHandler,
        parameters: [
          Param.new!(%{name: "slow", type: :integer, description: "Sleep ms", required: true})
        ]
      })

    # Register tools
    :ok = Registry.register(read_file)
    :ok = Registry.register(write_file)
    :ok = Registry.register(error_tool)
    :ok = Registry.register(slow_tool)

    :ok
  end

  describe "parse_tool_calls/1" do
    test "parses OpenAI-format tool calls with JSON arguments" do
      response = %{
        "tool_calls" => [
          %{
            "id" => "call_123",
            "type" => "function",
            "function" => %{
              "name" => "read_file",
              "arguments" => ~s({"path": "/src/main.ex"})
            }
          }
        ]
      }

      assert {:ok, [tool_call]} = Executor.parse_tool_calls(response)
      assert tool_call.id == "call_123"
      assert tool_call.name == "read_file"
      assert tool_call.arguments == %{"path" => "/src/main.ex"}
    end

    test "parses multiple tool calls" do
      response = %{
        "tool_calls" => [
          %{
            "id" => "call_1",
            "type" => "function",
            "function" => %{
              "name" => "read_file",
              "arguments" => ~s({"path": "/a.txt"})
            }
          },
          %{
            "id" => "call_2",
            "type" => "function",
            "function" => %{
              "name" => "read_file",
              "arguments" => ~s({"path": "/b.txt"})
            }
          }
        ]
      }

      assert {:ok, tool_calls} = Executor.parse_tool_calls(response)
      assert length(tool_calls) == 2
      assert Enum.at(tool_calls, 0).id == "call_1"
      assert Enum.at(tool_calls, 1).id == "call_2"
    end

    test "parses atom-keyed tool calls" do
      response = %{
        tool_calls: [
          %{
            id: "call_123",
            type: "function",
            function: %{
              name: "read_file",
              arguments: %{path: "/test.txt"}
            }
          }
        ]
      }

      assert {:ok, [tool_call]} = Executor.parse_tool_calls(response)
      assert tool_call.name == "read_file"
    end

    test "parses direct format without type wrapper" do
      tool_calls = [
        %{
          "id" => "call_123",
          "name" => "read_file",
          "arguments" => %{"path" => "/test.txt"}
        }
      ]

      assert {:ok, [tool_call]} = Executor.parse_tool_calls(tool_calls)
      assert tool_call.name == "read_file"
    end

    test "returns error for no tool calls" do
      assert {:error, :no_tool_calls} = Executor.parse_tool_calls(%{})
      assert {:error, :no_tool_calls} = Executor.parse_tool_calls(%{"tool_calls" => []})
      assert {:error, :no_tool_calls} = Executor.parse_tool_calls(%{"tool_calls" => nil})
    end

    test "returns error for invalid JSON in arguments" do
      response = %{
        "tool_calls" => [
          %{
            "id" => "call_123",
            "type" => "function",
            "function" => %{
              "name" => "read_file",
              "arguments" => "invalid json {"
            }
          }
        ]
      }

      assert {:error, {:invalid_tool_call, _msg}} = Executor.parse_tool_calls(response)
    end
  end

  describe "execute/2" do
    test "executes valid tool call successfully" do
      tool_call = %{id: "call_123", name: "read_file", arguments: %{"path" => "/test.txt"}}

      assert {:ok, result} = Executor.execute(tool_call)
      assert result.status == :ok
      assert result.tool_call_id == "call_123"
      assert result.tool_name == "read_file"
      assert result.content == "Contents of /test.txt"
      assert result.duration_ms >= 0
    end

    test "handles string-keyed tool call" do
      tool_call = %{
        "id" => "call_123",
        "name" => "read_file",
        "arguments" => %{"path" => "/test.txt"}
      }

      assert {:ok, result} = Executor.execute(tool_call)
      assert result.status == :ok
    end

    test "returns error result for non-existent tool" do
      tool_call = %{id: "call_123", name: "nonexistent_tool", arguments: %{}}

      assert {:ok, result} = Executor.execute(tool_call)
      assert result.status == :error
      assert result.content =~ "not found"
    end

    test "returns error result for missing required parameter" do
      tool_call = %{id: "call_123", name: "read_file", arguments: %{}}

      assert {:ok, result} = Executor.execute(tool_call)
      assert result.status == :error
      assert result.content =~ "missing required parameter"
    end

    test "returns error result for unknown parameter" do
      tool_call = %{
        id: "call_123",
        name: "read_file",
        arguments: %{"path" => "/test.txt", "unknown" => "param"}
      }

      assert {:ok, result} = Executor.execute(tool_call)
      assert result.status == :error
      assert result.content =~ "unknown parameter"
    end

    test "returns error result for wrong parameter type" do
      tool_call = %{id: "call_123", name: "read_file", arguments: %{"path" => 123}}

      assert {:ok, result} = Executor.execute(tool_call)
      assert result.status == :error
      assert result.content =~ "must be a string"
    end

    test "returns error result when handler returns error" do
      tool_call = %{id: "call_123", name: "error_tool", arguments: %{"error" => true}}

      assert {:ok, result} = Executor.execute(tool_call)
      assert result.status == :error
      assert result.content == "Intentional error"
    end

    test "handles timeout" do
      tool_call = %{id: "call_123", name: "slow_tool", arguments: %{"slow" => 500}}

      assert {:ok, result} = Executor.execute(tool_call, timeout: 100)
      assert result.status == :timeout
      assert result.content =~ "timed out"
    end

    test "tracks execution duration" do
      tool_call = %{id: "call_123", name: "slow_tool", arguments: %{"slow" => 50}}

      assert {:ok, result} = Executor.execute(tool_call, timeout: 5000)
      assert result.duration_ms >= 50
    end
  end

  describe "execute_batch/2" do
    test "executes multiple tool calls sequentially" do
      tool_calls = [
        %{id: "call_1", name: "read_file", arguments: %{"path" => "/a.txt"}},
        %{id: "call_2", name: "read_file", arguments: %{"path" => "/b.txt"}}
      ]

      assert {:ok, results} = Executor.execute_batch(tool_calls)
      assert length(results) == 2
      assert Enum.at(results, 0).tool_call_id == "call_1"
      assert Enum.at(results, 1).tool_call_id == "call_2"
    end

    test "executes in parallel when option set" do
      tool_calls = [
        %{id: "call_1", name: "slow_tool", arguments: %{"slow" => 50}},
        %{id: "call_2", name: "slow_tool", arguments: %{"slow" => 50}}
      ]

      start = System.monotonic_time(:millisecond)
      {:ok, results} = Executor.execute_batch(tool_calls, parallel: true, timeout: 5000)
      elapsed = System.monotonic_time(:millisecond) - start

      assert length(results) == 2
      # Parallel execution should be faster than sequential (50+50=100ms)
      assert elapsed < 150
    end

    test "handles mixed success and failure" do
      tool_calls = [
        %{id: "call_1", name: "read_file", arguments: %{"path" => "/a.txt"}},
        %{id: "call_2", name: "error_tool", arguments: %{"error" => true}},
        %{id: "call_3", name: "read_file", arguments: %{"path" => "/c.txt"}}
      ]

      assert {:ok, results} = Executor.execute_batch(tool_calls)

      assert Enum.at(results, 0).status == :ok
      assert Enum.at(results, 1).status == :error
      assert Enum.at(results, 2).status == :ok
    end

    test "returns empty list for empty input" do
      assert {:ok, []} = Executor.execute_batch([])
    end
  end

  describe "validate_tool_exists/1" do
    test "returns tool when it exists" do
      assert {:ok, tool} = Executor.validate_tool_exists("read_file")
      assert tool.name == "read_file"
    end

    test "returns error when tool not found" do
      assert {:error, :not_found} = Executor.validate_tool_exists("nonexistent")
    end
  end

  describe "validate_arguments/2" do
    test "returns ok for valid arguments" do
      {:ok, tool} = Registry.get("read_file")
      assert :ok = Executor.validate_arguments(tool, %{"path" => "/test.txt"})
    end

    test "returns error for invalid arguments" do
      {:ok, tool} = Registry.get("read_file")
      assert {:error, _} = Executor.validate_arguments(tool, %{})
    end
  end

  describe "integration: parse and execute" do
    test "full round-trip from LLM response to results" do
      llm_response = %{
        "tool_calls" => [
          %{
            "id" => "call_abc",
            "type" => "function",
            "function" => %{
              "name" => "read_file",
              "arguments" => ~s({"path": "/src/main.ex"})
            }
          }
        ]
      }

      # Parse
      assert {:ok, tool_calls} = Executor.parse_tool_calls(llm_response)

      # Execute
      assert {:ok, results} = Executor.execute_batch(tool_calls)

      # Convert to LLM messages
      messages = Result.to_llm_messages(results)

      assert [message] = messages
      assert message.role == "tool"
      assert message.tool_call_id == "call_abc"
      assert message.content == "Contents of /src/main.ex"
    end
  end

  describe "build_context/2" do
    test "returns error for invalid session ID format" do
      assert {:error, :invalid_session_id} = Executor.build_context("not-a-uuid")
    end

    test "raises FunctionClauseError for non-binary session ID" do
      assert_raise FunctionClauseError, fn ->
        Executor.build_context(123)
      end

      assert_raise FunctionClauseError, fn ->
        Executor.build_context(nil)
      end
    end

    test "returns not_found for non-existent session" do
      # Use a valid UUID format but session doesn't exist
      valid_uuid = "550e8400-e29b-41d4-a716-446655440000"
      assert {:error, :not_found} = Executor.build_context(valid_uuid)
    end

    test "returns context with custom timeout" do
      valid_uuid = "550e8400-e29b-41d4-a716-446655440001"
      assert {:error, :not_found} = Executor.build_context(valid_uuid, timeout: 60_000)
    end
  end

  describe "enrich_context/1" do
    test "returns context unchanged if already has project_root" do
      context = %{session_id: "abc123", project_root: "/path/to/project"}
      assert {:ok, ^context} = Executor.enrich_context(context)
    end

    test "returns error for missing session_id" do
      assert {:error, :missing_session_id} = Executor.enrich_context(%{project_root: "/path"})
      assert {:error, :missing_session_id} = Executor.enrich_context(%{})
    end

    test "returns not_found for non-existent session" do
      assert {:error, :not_found} =
               Executor.enrich_context(%{session_id: "nonexistent-session-id"})
    end
  end

  describe "memory_tools/0" do
    test "returns list of memory tool names" do
      tools = Executor.memory_tools()

      assert is_list(tools)
      assert "remember" in tools
      assert "recall" in tools
      assert "forget" in tools
    end
  end

  describe "memory_tool?/1" do
    test "returns true for memory tools" do
      assert Executor.memory_tool?("remember")
      assert Executor.memory_tool?("recall")
      assert Executor.memory_tool?("forget")
    end

    test "returns false for non-memory tools" do
      refute Executor.memory_tool?("read_file")
      refute Executor.memory_tool?("write_file")
      refute Executor.memory_tool?("grep")
    end

    test "returns false for non-binary input" do
      refute Executor.memory_tool?(123)
      refute Executor.memory_tool?(:remember)
      refute Executor.memory_tool?(nil)
    end
  end

  describe "broadcast_tool_call/4" do
    test "broadcasts tool call event" do
      # This just verifies the function doesn't crash
      # Actual PubSub delivery would require subscription setup
      assert :ok = Executor.broadcast_tool_call("session123", "read_file", %{"path" => "/test.txt"}, "call_123")
    end

    test "broadcasts with nil session_id" do
      assert :ok = Executor.broadcast_tool_call(nil, "read_file", %{}, "call_456")
    end
  end

  describe "broadcast_tool_result/2" do
    test "broadcasts tool result event" do
      result = Result.ok("call_123", "read_file", "file contents", 10)
      assert :ok = Executor.broadcast_tool_result("session123", result)
    end

    test "broadcasts error result" do
      result = Result.error("call_123", "read_file", "some error", 5)
      assert :ok = Executor.broadcast_tool_result("session123", result)
    end

    test "broadcasts with nil session_id" do
      result = Result.ok("call_123", "read_file", "contents", 10)
      assert :ok = Executor.broadcast_tool_result(nil, result)
    end
  end

  describe "pubsub_topic/1" do
    test "returns global topic for nil session_id" do
      assert Executor.pubsub_topic(nil) == "tui.events"
    end

    test "returns session-specific topic for valid session_id" do
      assert Executor.pubsub_topic("session123") == "tui.events.session123"
    end
  end

  describe "parse_tool_calls/1 with choices format" do
    test "parses from full API response with choices key" do
      response = %{
        "choices" => [
          %{
            "message" => %{
              "tool_calls" => [
                %{
                  "id" => "call_xyz",
                  "type" => "function",
                  "function" => %{
                    "name" => "read_file",
                    "arguments" => ~s({"path": "/choices.txt"})
                  }
                }
              ]
            }
          }
        ]
      }

      assert {:ok, [tool_call]} = Executor.parse_tool_calls(response)
      assert tool_call.id == "call_xyz"
      assert tool_call.name == "read_file"
    end

    test "returns error for empty choices" do
      response = %{"choices" => []}
      assert {:error, :no_tool_calls} = Executor.parse_tool_calls(response)
    end
  end

  describe "execute/2 with custom executor" do
    test "uses custom executor function when provided" do
      tool_call = %{id: "call_123", name: "read_file", arguments: %{"path" => "/test.txt"}}

      custom_executor = fn _tool, _args, _context ->
        {:ok, "custom executor result"}
      end

      assert {:ok, result} = Executor.execute(tool_call, executor: custom_executor)
      assert result.status == :ok
      assert result.content == "custom executor result"
    end

    test "custom executor can return errors" do
      tool_call = %{id: "call_123", name: "read_file", arguments: %{"path" => "/test.txt"}}

      custom_executor = fn _tool, _args, _context ->
        {:error, "custom error"}
      end

      assert {:ok, result} = Executor.execute(tool_call, executor: custom_executor)
      assert result.status == :error
      assert result.content == "custom error"
    end
  end

  describe "execute/2 with context" do
    test "executes with context containing session_id and project_root" do
      tool_call = %{id: "call_123", name: "read_file", arguments: %{"path" => "/test.txt"}}
      context = %{session_id: "test-session", project_root: "/tmp"}

      assert {:ok, result} = Executor.execute(tool_call, context: context)
      assert result.status == :ok
    end
  end

  describe "execute_batch/2 with single tool call" do
    test "handles single tool call in batch" do
      tool_calls = [
        %{id: "call_1", name: "read_file", arguments: %{"path" => "/single.txt"}}
      ]

      assert {:ok, results} = Executor.execute_batch(tool_calls)
      assert length(results) == 1
      assert Enum.at(results, 0).tool_call_id == "call_1"
    end
  end

  describe "execute_batch/2 timeout handling" do
    test "applies timeout to parallel execution" do
      tool_calls = [
        %{id: "call_1", name: "slow_tool", arguments: %{"slow" => 5000}},
        %{id: "call_2", name: "slow_tool", arguments: %{"slow" => 5000}}
      ]

      # Should timeout before 5000ms
      start = System.monotonic_time(:millisecond)
      {:ok, results} = Executor.execute_batch(tool_calls, parallel: true, timeout: 100)
      elapsed = System.monotonic_time(:millisecond) - start

      # Both should have timed out
      assert Enum.all?(results, fn r -> r.status == :timeout end)
      assert elapsed < 5000
    end
  end
end
