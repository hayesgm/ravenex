defmodule Ravenex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ravenex,
      version: "0.0.7",
      elixir: "~> 1.0",
      description: """
        Ravenex is an Elixir client for Sentry. Automatically
        send error notifications to Sentry. Easily connects
        with Phoenix through adding a logger or Plug.
      """,
      package: package,
      deps: deps
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
      applications: [:idna, :hackney, :httpoison, :uuid]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8"},
      {:poison, "~> 2.0"},
      {:uuid, "~> 1.1.3"},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end
end
