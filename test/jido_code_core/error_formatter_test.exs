defmodule JidoCodeCore.ErrorFormatterTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.ErrorFormatter

  doctest ErrorFormatter

  describe "format/1" do
    test "returns binary string as-is" do
      assert ErrorFormatter.format("file not found") == "file not found"
      assert ErrorFormatter.format("an error occurred") == "an error occurred"
    end

    test "converts atom to string" do
      assert ErrorFormatter.format(:enoent) == "enoent"
      assert ErrorFormatter.format(:not_found) == "not_found"
      assert ErrorFormatter.format(:permission_denied) == "permission_denied"
    end

    test "converts charlist to string" do
      assert ErrorFormatter.format(~c"hello") == "hello"
      assert ErrorFormatter.format(~c"error") == "error"
    end

    test "unwraps {:error, reason} tuples" do
      assert ErrorFormatter.format({:error, :permission_denied}) == "permission_denied"
      assert ErrorFormatter.format({:error, "file not found"}) == "file not found"
    end

    test "extracts error from {:lua_error, error, stack} tuples" do
      assert ErrorFormatter.format({:lua_error, "syntax error", []}) == "syntax error"
      assert ErrorFormatter.format({:lua_error, :runtime_error, ["line 1"]}) == "runtime_error"
    end

    test "extracts message from maps with :message key" do
      assert ErrorFormatter.format(%{message: "Invalid input"}) == "Invalid input"
      assert ErrorFormatter.format(%{message: "Something went wrong"}) == "Something went wrong"
    end

    test "handles maps with binary message" do
      result = ErrorFormatter.format(%{message: "test error"})
      assert result == "test error"
    end

    test "returns inspected string for unknown types" do
      assert ErrorFormatter.format(123) == "123"
      assert ErrorFormatter.format(45.67) == "45.67"
      # Lists are treated as charlists by to_string/1, so [1,2,3] becomes <<1,2,3>>
      assert ErrorFormatter.format([1, 2, 3]) == <<1, 2, 3>>
      assert ErrorFormatter.format(%{key: "value"}) == "%{key: \"value\"}"
    end

    test "handles empty map" do
      assert ErrorFormatter.format(%{}) == "%{}"
    end

    test "handles nested error tuples" do
      assert ErrorFormatter.format({:error, {:error, :nested}}) == "nested"
    end

    test "handles tuple with lua_error and binary error" do
      assert ErrorFormatter.format({:lua_error, "syntax error", ["stack trace"]}) == "syntax error"
    end
  end

  describe "integration tests" do
    test "formats various error types consistently" do
      errors = [
        "simple string",
        :atom_error,
        {:error, :wrapped_error},
        {:lua_error, "lua error", []},
        %{message: "map error"}
      ]

      Enum.each(errors, fn error ->
        result = ErrorFormatter.format(error)
        assert is_binary(result)
        assert String.length(result) > 0
      end)
    end

    test "handles real-world error scenarios" do
      # File error
      assert ErrorFormatter.format({:error, :enoent}) == "enoent"

      # Lua execution error
      assert ErrorFormatter.format({:lua_error, "attempt to index nil value", ["line 10"]}) ==
               "attempt to index nil value"

      # Structured error
      assert ErrorFormatter.format(%{message: "Validation failed", field: :email}) ==
               "Validation failed"
    end
  end
end
