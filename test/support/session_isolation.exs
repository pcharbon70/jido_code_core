defmodule JidoCodeCore.TestHelpers.SessionIsolation do
  @moduledoc """
  Test helper for isolating session state during tests.

  The SessionRegistry is an ETS table shared across all tests. This module
  provides functions to ensure tests start with a clean session registry
  and clean up after themselves.

  ## Usage

  For tests that interact with SessionRegistry, add this to your setup:

      setup do
        JidoCodeCore.TestHelpers.SessionIsolation.isolate()
      end

  This will:
  1. Ensure required ETS tables exist (SessionRegistry)
  2. Clear all sessions from the registry before the test
  3. Register cleanup to clear sessions after the test

  ## For ExUnit.Case

  You can also use the `use` macro for automatic isolation:

      defmodule MyTest do
        use ExUnit.Case
        use JidoCodeCore.TestHelpers.SessionIsolation

        # All tests will have isolated session state
      end
  """

  alias JidoCodeCore.SessionRegistry

  @doc """
  Clears all sessions from SessionRegistry and registers cleanup.

  Call this in your test setup to ensure session isolation.

  ## Example

      setup do
        JidoCodeCore.TestHelpers.SessionIsolation.isolate()
      end
  """
  @spec isolate() :: :ok
  def isolate do
    ensure_tables_exist()
    clear_sessions()

    ExUnit.Callbacks.on_exit(fn ->
      clear_sessions()
    end)

    :ok
  end

  @doc """
  Ensures all required ETS tables exist.

  Creates SessionRegistry table if it doesn't exist.
  """
  @spec ensure_tables_exist() :: :ok
  def ensure_tables_exist do
    # Ensure SessionRegistry table exists
    SessionRegistry.create_table()

    :ok
  end

  @doc """
  Clears all sessions from the SessionRegistry.

  Can be called manually when you need to reset session state.
  """
  @spec clear_sessions() :: :ok
  def clear_sessions do
    try do
      SessionRegistry.list_all()
      |> Enum.each(fn session ->
        SessionRegistry.unregister(session.id)
      end)
    rescue
      # Registry might not exist yet in some test scenarios
      ArgumentError -> :ok
    catch
      :exit, _ -> :ok
    end

    :ok
  end

  @doc """
  Macro for automatic session isolation in test modules.

  ## Usage

      defmodule MyTest do
        use ExUnit.Case
        use JidoCodeCore.TestHelpers.SessionIsolation

        test "my test" do
          # SessionRegistry is clean
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      setup do
        JidoCodeCore.TestHelpers.SessionIsolation.isolate()
      end
    end
  end
end
