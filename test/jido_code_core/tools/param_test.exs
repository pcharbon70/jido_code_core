defmodule JidoCodeCore.Tools.ParamTest do
  use ExUnit.Case, async: true

  alias JidoCodeCore.Tools.Param

  doctest Param

  describe "new/1" do
    test "creates valid param with string type" do
      assert {:ok, param} =
               Param.new(%{
                 name: "path",
                 type: :string,
                 description: "File path"
               })

      assert param.name == "path"
      assert param.type == :string
      assert param.description == "File path"
      assert param.required == true
      assert param.default == nil
    end

    test "creates valid param with all types" do
      valid_types = [:string, :integer, :number, :boolean, :array, :object]

      Enum.each(valid_types, fn type ->
        assert {:ok, %Param{type: ^type}} =
                 Param.new(%{
                   name: "test",
                   type: type,
                   description: "test param"
                 })
      end)
    end

    test "creates param with required: false" do
      assert {:ok, param} =
               Param.new(%{
                 name: "optional",
                 type: :string,
                 description: "Optional param",
                 required: false
               })

      refute param.required
    end

    test "creates param with default value" do
      assert {:ok, param} =
               Param.new(%{
                 name: "flag",
                 type: :boolean,
                 description: "A flag",
                 default: false
               })

      assert param.default == false
    end

    test "creates array param with items type" do
      assert {:ok, param} =
               Param.new(%{
                 name: "patterns",
                 type: :array,
                 description: "Patterns",
                 items: :string
               })

      assert param.items == :string
    end

    test "creates object param with properties" do
      assert {:ok, param} =
               Param.new(%{
                 name: "options",
                 type: :object,
                 description: "Options",
                 properties: [
                   %{name: "key", type: :string, description: "Key"},
                   %{name: "value", type: :string, description: "Value"}
                 ]
               })

      assert length(param.properties) == 2
      assert hd(param.properties).name == "key"
    end

    test "creates param with enum values" do
      assert {:ok, param} =
               Param.new(%{
                 name: "mode",
                 type: :string,
                 description: "Mode",
                 enum: ["read", "write"]
               })

      assert param.enum == ["read", "write"]
    end

    test "converts atom name to string" do
      assert {:ok, param} =
               Param.new(%{
                 name: :path,
                 type: :string,
                 description: "File path"
               })

      assert param.name == "path"
      assert is_binary(param.name)
    end

    test "returns error for missing name" do
      assert {:error, "name is required"} =
               Param.new(%{
                 type: :string,
                 description: "test"
               })
    end

    test "returns error for empty name" do
      assert {:error, "name must be a non-empty string"} =
               Param.new(%{
                 name: "",
                 type: :string,
                 description: "test"
               })
    end

    test "returns error for missing type" do
      assert {:error, "type is required"} =
               Param.new(%{
                 name: "test",
                 description: "test"
               })
    end

    test "returns error for invalid type" do
      assert {:error, message} =
               Param.new(%{
                 name: "test",
                 type: :invalid,
                 description: "test"
               })

      assert String.contains?(message, "must be one of")
      assert String.contains?(message, "invalid")
    end

    test "returns error for missing description" do
      assert {:error, "description is required"} =
               Param.new(%{
                 name: "test",
                 type: :string
               })
    end

    test "returns error for empty description" do
      assert {:error, "description must be a non-empty string"} =
               Param.new(%{
                 name: "test",
                 type: :string,
                 description: ""
               })
    end

    test "returns error for invalid array items type" do
      assert {:error, "items must be a valid type for array parameters"} =
               Param.new(%{
                 name: "list",
                 type: :array,
                 description: "A list",
                 items: :invalid
               })
    end

    test "returns error for invalid property in object" do
      assert {:error, "invalid property: \"invalid\""} =
               Param.new(%{
                 name: "obj",
                 type: :object,
                 description: "An object",
                 properties: ["invalid"]
               })
    end
  end

  describe "new!/1" do
    test "returns param for valid input" do
      param =
        Param.new!(%{
          name: "test",
          type: :string,
          description: "test param"
        })

      assert param.name == "test"
    end

    test "raises for invalid input" do
      assert_raise ArgumentError, "name is required", fn ->
        Param.new!(%{type: :string, description: "test"})
      end
    end

    test "raises ArgumentError with proper message" do
      assert_raise ArgumentError, ~r/invalid type/, fn ->
        Param.new!(%{name: "test", type: :invalid, description: "test"})
      end
    end
  end

  describe "to_json_schema/1" do
    test "converts string param to JSON schema" do
      param = %Param{name: "path", type: :string, description: "File path", required: true}
      schema = Param.to_json_schema(param)

      assert schema.type == "string"
      assert schema.description == "File path"
    end

    test "converts integer param to JSON schema" do
      param = %Param{name: "count", type: :integer, description: "Count", required: true}
      schema = Param.to_json_schema(param)

      assert schema.type == "integer"
    end

    test "converts number param to JSON schema" do
      param = %Param{name: "rate", type: :number, description: "Rate", required: true}
      schema = Param.to_json_schema(param)

      assert schema.type == "number"
    end

    test "converts boolean param to JSON schema" do
      param = %Param{name: "flag", type: :boolean, description: "Flag", required: true}
      schema = Param.to_json_schema(param)

      assert schema.type == "boolean"
    end

    test "converts array param to JSON schema with items" do
      param = %Param{
        name: "items",
        type: :array,
        description: "Items",
        items: :string,
        required: true
      }

      schema = Param.to_json_schema(param)

      assert schema.type == "array"
      assert schema.items.type == "string"
    end

    test "converts object param to JSON schema with properties" do
      nested1 = Param.new!(%{name: "key", type: :string, description: "Key"})
      nested2 = Param.new!(%{name: "value", type: :string, description: "Value"})

      param = %Param{
        name: "obj",
        type: :object,
        description: "Object",
        properties: [nested1, nested2],
        required: true
      }

      schema = Param.to_json_schema(param)

      assert schema.type == "object"
      assert is_map(schema.properties)
      assert schema.properties["key"].type == "string"
      assert schema.properties["value"].type == "string"
      assert "key" in schema.required
      assert "value" in schema.required
    end

    test "includes default value when present" do
      param = %Param{
        name: "flag",
        type: :boolean,
        description: "Flag",
        default: false,
        required: false
      }

      schema = Param.to_json_schema(param)

      assert schema.default == false
    end

    test "includes enum values when present" do
      param = %Param{
        name: "mode",
        type: :string,
        description: "Mode",
        enum: ["a", "b"],
        required: true
      }

      schema = Param.to_json_schema(param)

      assert schema.enum == ["a", "b"]
    end

    test "handles param with all options" do
      param = %Param{
        name: "complex",
        type: :array,
        description: "Complex param",
        required: false,
        default: [],
        items: :string,
        enum: ["a", "b"]
      }

      schema = Param.to_json_schema(param)

      assert schema.type == "array"
      assert schema.items.type == "string"
      assert schema.default == []
      assert schema.enum == ["a", "b"]
    end
  end

  describe "integration tests" do
    test "full workflow: create and convert to JSON schema" do
      {:ok, param} =
        Param.new(%{
          name: "file_path",
          type: :string,
          description: "Path to the file",
          required: true
        })

      assert param.name == "file_path"
      assert param.required == true

      schema = Param.to_json_schema(param)
      assert schema.type == "string"
      assert schema.description == "Path to the file"
    end

    test "complex nested param workflow" do
      {:ok, nested} =
        Param.new(%{
          name: "nested_key",
          type: :string,
          description: "Nested key"
        })

      {:ok, param} =
        Param.new(%{
          name: "config",
          type: :object,
          description: "Configuration object",
          properties: [nested],
          required: false,
          default: %{}
        })

      refute param.required
      assert param.default == %{}

      schema = Param.to_json_schema(param)
      assert schema.type == "object"
      assert is_map(schema.properties)
      assert schema.default == %{}
    end
  end
end
