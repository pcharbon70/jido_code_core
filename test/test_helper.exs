# Compile test support modules
Code.require_file("support/env_isolation.exs", __DIR__)
Code.require_file("support/session_isolation.exs", __DIR__)
Code.require_file("support/session_test_helpers.exs", __DIR__)
Code.require_file("support/memory_test_helpers.exs", __DIR__)

# Ensure JidoCodeCore application infrastructure is started before running tests
# This ensures all GenServers, Registries, and Supervisors are initialized
{:ok, _} = Application.ensure_all_started(:jido_code_core)

# Ensure all required ETS tables exist before any tests run
# This prevents race conditions when tests run in parallel
JidoCodeCore.TestHelpers.SessionIsolation.ensure_tables_exist()

# Exclude LLM integration tests by default
# Run with: mix test --include llm
ExUnit.start(exclude: [:llm, :property])
