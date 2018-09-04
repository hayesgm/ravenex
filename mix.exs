defmodule Ravenex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ravenex,
      version: "0.1.0",
      elixir: "~> 1.7",
      description: """
        Ravenex is an Elixir client for Sentry. Automatically
        send error notifications to Sentry. Easily connects
        with Phoenix through adding a logger or Plug.
      """,
      package: package(),
      deps: deps()
   ]
  end

  def package do
    [
      maintainers: ["Geoffrey Hayes"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/hayesgm/ravenex"}
   ]
  end

  def application do
    [
      applications: [:idna, :hackney, :httpoison, :logger, :elixir_uuid],
      mod: { RavenexApp, [] }
    ]
  end

  defp deps do
    [
      {:gen_retry, "~> 1.0.1", only: :test},
      {:httpoison, "~> 0.8"},
      {:poison, "~> 2.0 or ~> 3.0"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end
end
