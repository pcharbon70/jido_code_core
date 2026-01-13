defmodule JidoCodeCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :jido_code_core,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_exclude: [:llm, :property]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {JidoCodeCore.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Agent framework
      {:jido, "~> 1.2", path: "../jido"},
      {:jido_ai, "~> 2.0", path: "../jido_ai"},

      # Communication
      {:phoenix_pubsub, "~> 2.1"},

      # Security
      {:luerl, "~> 1.2"},

      # Knowledge graph
      {:rdf, "~> 2.0"},
      {:libgraph, "~> 0.16"},
      # Triple store for long-term memory (requires rocksdb - use local path)
      {:triple_store, path: "/home/ducky/code/triple_store"},

      # JSON encoding
      {:jason, "~> 1.4"},

      # Web tools
      {:floki, "~> 0.36"},

      # Dev/Test
      {:ex_doc, "~> 0.34", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
