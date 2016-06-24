defmodule Ravenex.LoggerBackend do
  use GenEvent

  def init(__MODULE__) do
    {:ok, configure([])}
  end

  def handle_call({:configure, opts}, _state) do
    {:ok, :ok, configure(opts)}
  end

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, event}, %{metadata: keys} = state) do
    if proceed?(event) and meet_level?(level, state.level) do
      post_event(event, get_raven_level(level), keys)
    end
    {:ok, state}
  end

  defp proceed?({Logger, _msg, _ts, meta}) do
    Keyword.get(meta, :ravenex, true)
  end

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp post_event({Logger, msg, _ts, meta}, level, keys) do
    msg = IO.chardata_to_string(msg)
    meta = take_into_map(meta, keys)

    Ravenex.LoggerParser.parse(msg)
    |> Ravenex.Notifier.notify([level: level, params: meta])
  end

  defp take_into_map(metadata, keys) do
    Enum.reduce metadata, %{}, fn({key, val}, acc) ->
      if key in keys, do: Map.put(acc, key, val), else: acc
    end
  end

  defp configure(opts) do
    config = Application.get_env(:logger, __MODULE__, []) |> Keyword.merge(opts)

    Application.put_env(:logger, __MODULE__, config)

    %{
      level: Application.get_env(:ravenex, :logger_level, :error),
      metadata: Keyword.get(config, :metadata, [])
    }
  end

  # Given a logger's level, send a similar level to raven
  defp get_raven_level(logger_level) do
    %{
      debug: "debug",
      info: "info",
      warn: "warning",
      error: "error"
    }[logger_level]
  end
end
