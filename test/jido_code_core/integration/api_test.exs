defmodule JidoCodeCore.Integration.APITest do
  use ExUnit.Case

  @moduledoc """
  Integration tests for JidoCodeCore public API.

  These tests verify the API functions work correctly by delegating
  to underlying implementation modules.
  """

  defp unique_id, do: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)

  describe "1.4.2 API Integration" do
    test "1.4.2.1 Start Core application successfully" do
      # Application should be startable
      assert {:ok, _pid} = Application.ensure_all_started(:jido_code_core)
    end

    test "1.4.2.2 Session API module exists and has correct functions" do
      # Ensure the module is loaded
      Code.ensure_loaded!(JidoCodeCore.API.Session)

      # Verify the API module exists and has the expected functions
      assert function_exported?(JidoCodeCore.API.Session, :start_session, 1)
      assert function_exported?(JidoCodeCore.API.Session, :stop_session, 1)
      assert function_exported?(JidoCodeCore.API.Session, :list_sessions, 0)
      assert function_exported?(JidoCodeCore.API.Session, :get_session, 1)
      assert function_exported?(JidoCodeCore.API.Session, :set_session_config, 2)
      assert function_exported?(JidoCodeCore.API.Session, :set_session_language, 2)
    end

    test "1.4.2.3 Tools API module exists and has correct functions" do
      # Ensure the module is loaded
      Code.ensure_loaded!(JidoCodeCore.API.Tools)

      # Verify the Tools API module exists and has the expected functions
      assert function_exported?(JidoCodeCore.API.Tools, :list_tools, 0)
      assert function_exported?(JidoCodeCore.API.Tools, :get_tool_schema, 1)
      assert function_exported?(JidoCodeCore.API.Tools, :execute_tool, 4)
    end

    test "1.4.2.4 Config API module exists and has correct functions" do
      # Ensure the module is loaded
      Code.ensure_loaded!(JidoCodeCore.API.Config)

      # Verify the Config API module exists and has the expected functions
      assert function_exported?(JidoCodeCore.API.Config, :get_global_settings, 0)
      assert function_exported?(JidoCodeCore.API.Config, :list_providers, 0)
      assert function_exported?(JidoCodeCore.API.Config, :list_models_for_provider, 1)
    end

    test "1.4.2.5 PubSubHelpers API module exists" do
      # Verify PubSubHelpers exists and has the expected functions
      assert function_exported?(JidoCodeCore.PubSubHelpers, :broadcast, 2)
      assert function_exported?(JidoCodeCore.PubSubHelpers, :session_topic, 1)
      assert function_exported?(JidoCodeCore.PubSubHelpers, :global_topic, 0)
    end

    test "1.4.2.6 Session struct exists and is valid" do
      # Verify the Session struct exists
      session = %JidoCodeCore.Session{
        id: unique_id(),
        project_path: System.tmp_dir!(),
        name: "Test Session"
      }

      assert is_binary(session.id)
      assert is_binary(session.project_path)
      assert is_binary(session.name)
      assert is_struct(session)
    end

    test "1.4.2.7 Tool.Result struct exists" do
      # Verify the Tool.Result struct exists
      result = %JidoCodeCore.Tools.Result{
        tool_call_id: "test_id",
        tool_name: "test_tool",
        status: :ok,
        content: "test content",
        duration_ms: 10
      }

      assert result.status == :ok
      assert result.content == "test content"
    end
  end
end
