defmodule JidoCodeCore.Tools.ResultTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Tools.Result

  doctest Result

  describe "new struct" do
    test "creates struct with required fields" do
      result = %Result{
        tool_call_id: "call_123",
        tool_name: "test_tool",
        status: :ok,
        content: "result"
      }

      assert result.tool_call_id == "call_123"
      assert result.tool_name == "test_tool"
      assert result.status == :ok
      assert result.content == "result"
      assert result.duration_ms == 0  # default value
    end
  end

  describe "ok/4" do
    test "creates successful result" do
      result = Result.ok("call_123", "read_file", "file contents", 45)

      assert result.tool_call_id == "call_123"
      assert result.tool_name == "read_file"
      assert result.status == :ok
      assert result.content == "file contents"
      assert result.duration_ms == 45
    end

    test "uses default duration_ms of 0" do
      result = Result.ok("call_123", "read_file", "file contents")

      assert result.duration_ms == 0
    end

    test "formats binary content as-is" do
      result = Result.ok("call_123", "test", "string content")
      assert result.content == "string content"
    end

    test "formats map content as JSON" do
      result = Result.ok("call_123", "test", %{"key" => "value"})
      assert result.content == ~s({"key":"value"})
    end

    test "formats list content as JSON" do
      result = Result.ok("call_123", "test", [1, 2, 3])
      assert result.content == "[1,2,3]"
    end

    test "formats other content with inspect" do
      result = Result.ok("call_123", "test", :atom)
      assert result.content == ":atom"
    end
  end

  describe "error/4" do
    test "creates error result" do
      result = Result.error("call_123", "read_file", :file_not_found, 12)

      assert result.tool_call_id == "call_123"
      assert result.tool_name == "read_file"
      assert result.status == :error
      assert result.content == "file_not_found"
      assert result.duration_ms == 12
    end

    test "uses default duration_ms of 0" do
      result = Result.error("call_123", "read_file", :not_found)
      assert result.duration_ms == 0
    end

    test "formats atom error reasons" do
      result = Result.error("call_123", "test", :enoent)
      assert result.content == "enoent"
    end

    test "formats string error reasons" do
      result = Result.error("call_123", "test", "custom error")
      assert result.content == "custom error"
    end

    test "formats tuple error reasons" do
      result = Result.error("call_123", "test", {:error, :nested})
      assert result.content == "nested"
    end

    test "formats lua error reasons" do
      result = Result.error("call_123", "test", {:lua_error, "syntax error", []})
      assert result.content == "syntax error"
    end

    test "formats map error with message" do
      result = Result.error("call_123", "test", %{message: "map error"})
      assert result.content == "map error"
    end
  end

  describe "timeout/3" do
    test "creates timeout result" do
      result = Result.timeout("call_123", "slow_tool", 30000)

      assert result.tool_call_id == "call_123"
      assert result.tool_name == "slow_tool"
      assert result.status == :timeout
      assert result.duration_ms == 30000
    end

    test "includes timeout message in content" do
      result = Result.timeout("call_123", "tool", 5000)
      assert result.content == "Tool execution timed out after 5000ms"
    end
  end

  describe "ok?/1" do
    test "returns true for :ok status" do
      result = Result.ok("call_123", "test", "content")
      assert Result.ok?(result)
    end

    test "returns false for :error status" do
      result = Result.error("call_123", "test", :error)
      refute Result.ok?(result)
    end

    test "returns false for :timeout status" do
      result = Result.timeout("call_123", "test", 5000)
      refute Result.ok?(result)
    end
  end

  describe "error?/1" do
    test "returns true for :error status" do
      result = Result.error("call_123", "test", :error)
      assert Result.error?(result)
    end

    test "returns true for :timeout status" do
      result = Result.timeout("call_123", "test", 5000)
      assert Result.error?(result)
    end

    test "returns false for :ok status" do
      result = Result.ok("call_123", "test", "content")
      refute Result.error?(result)
    end
  end

  describe "to_llm_message/1" do
    test "converts :ok result to LLM message format" do
      result = Result.ok("call_123", "test", "success")

      message = Result.to_llm_message(result)

      assert message.role == "tool"
      assert message.tool_call_id == "call_123"
      assert message.content == "success"
    end

    test "converts :error result to LLM message with error prefix" do
      result = Result.error("call_123", "test", "failed")

      message = Result.to_llm_message(result)

      assert message.role == "tool"
      assert message.tool_call_id == "call_123"
      assert message.content == "Error: failed"
    end

    test "converts :timeout result to LLM message with error prefix" do
      result = Result.timeout("call_123", "tool", 5000)

      message = Result.to_llm_message(result)

      assert message.role == "tool"
      assert message.tool_call_id == "call_123"
      assert message.content == "Error: Tool execution timed out after 5000ms"
    end
  end

  describe "to_llm_messages/1" do
    test "converts list of results to list of LLM messages" do
      results = [
        Result.ok("call_1", "test", "result 1"),
        Result.ok("call_2", "test", "result 2")
      ]

      messages = Result.to_llm_messages(results)

      assert length(messages) == 2
      assert Enum.at(messages, 0).tool_call_id == "call_1"
      assert Enum.at(messages, 0).role == "tool"
      assert Enum.at(messages, 1).tool_call_id == "call_2"
      assert Enum.at(messages, 1).role == "tool"
    end

    test "handles empty list" do
      assert Result.to_llm_messages([]) == []
    end

    test "handles single result" do
      results = [Result.ok("call_1", "test", "result")]
      messages = Result.to_llm_messages(results)

      assert length(messages) == 1
      assert hd(messages).tool_call_id == "call_1"
    end
  end

  describe "integration tests" do
    test "full workflow: ok result to LLM message" do
      result = Result.ok("call_abc", "read_file", "file contents", 10)

      assert Result.ok?(result)
      refute Result.error?(result)

      message = Result.to_llm_message(result)
      assert message.role == "tool"
      assert message.tool_call_id == "call_abc"
      assert message.content == "file contents"
    end

    test "full workflow: error result to LLM message" do
      result = Result.error("call_xyz", "write_file", {:error, :permission_denied}, 5)

      refute Result.ok?(result)
      assert Result.error?(result)

      message = Result.to_llm_message(result)
      assert message.role == "tool"
      assert message.tool_call_id == "call_xyz"
      assert message.content == "Error: permission_denied"
    end

    test "full workflow: timeout result to LLM message" do
      result = Result.timeout("call_timeout", "slow_operation", 30000)

      refute Result.ok?(result)
      assert Result.error?(result)

      message = Result.to_llm_message(result)
      assert message.role == "tool"
      assert message.content == "Error: Tool execution timed out after 30000ms"
    end
  end
end
