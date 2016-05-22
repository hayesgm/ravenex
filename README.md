# Ravenex ![Package Version](https://img.shields.io/hexpm/v/ravenex.svg)

Elixir client for the [Sentry](https://getsentry.com), based on [Airbrakex](https://github.com/fazibear/airbrakex).

## Installation

Add Ravenex as a dependency to your `mix.exs` file:

```elixir
def application do
  [applications: [:ravenex]]
end

defp deps do
  [{:ravenex, "~> 0.0.1"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

### Configuration

It requires `dsn` configuration parameters to be set
in your application environment, usually defined in your `config/config.exs`.
`logger_level` and `environment` are optional.

```elixir
config :ravenex,
  dsn: "https://xxx:yyy@app.getsentry.com/12345",
  logger_level: :error,
  environment: Mix.env
```

You may also set DSN from a runtime env var:

```elixir
config :ravenex,
  dsn: {:system, "RAVEN_DSN"}
```

## Usage

```elixir
try do
  IO.inspect("test",[],"")
rescue
  exception -> Ravenex.notify(exception)
end
```

### Logger Backend

There is a Logger backend to send logs to the Sentry,
which could be configured as follows:

```elixir
config :logger,
  backends: [Ravenex.LoggerBackend]
```

### Plug

You can plug `Ravenex.Plug` in your web application Plug stack to send all exceptions to Sentry

```elixir
defmodule YourApp.Router do
  use Phoenix.Router
  use Ravenex.Plug

  # ...
end
```

## Attributions

This project is a direct port of Airbrakex for Sentry. Many thanks to Michał Kalbarczyk for building and releasing that library. Additional code and inspiration from Stanislav Vishnevskiy and [raven-elixir](https://github.com/vishnevskiy/raven-elixir).

 - [Airbrakex](https://github.com/fazibear/airbrakex)
 - [raven-elixir](https://github.com/vishnevskiy/raven-elixir)
