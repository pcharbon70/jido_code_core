defmodule JidoCodeCore.Application do
  @moduledoc """
  OTP Application for JidoCodeCore.

  This application provides the core infrastructure for JidoCode, including:
  - Session management (creation, tracking, lifecycle)
  - Settings management (global + local JSON configuration)
  - Memory subsystem (short-term and long-term memory stores)
  - PubSub for inter-process communication
  - Agent system (LLM agents for AI interaction)

  The Application starts minimal infrastructure children that are shared
  between JidoCode and other consumers of the Core library.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Settings cache (must start before anything that might use Settings)
      JidoCodeCore.Settings.Cache,

      # PubSub for agent-TUI and inter-process communication
      {Phoenix.PubSub, name: JidoCodeCore.PubSub},

      # Registry for session process lookup (Session.Supervisor, Manager, State)
      {Registry, keys: :unique, name: JidoCodeCore.Session.ProcessRegistry},

      # Task.Supervisor for async task supervision
      {Task.Supervisor, name: JidoCodeCore.TaskSupervisor},

      # Session supervisor (DynamicSupervisor for session processes)
      JidoCodeCore.SessionSupervisor,

      # Memory subsystem supervisor (manages StoreManager for long-term memory)
      JidoCodeCore.Memory.Supervisor
    ]

    opts = [strategy: :one_for_one, name: JidoCodeCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
