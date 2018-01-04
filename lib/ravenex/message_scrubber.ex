defmodule MessageScrubber do
  def start_link() do
    Agent.start_link(fn ->
      process_scrub_config()
    end, name: __MODULE__)
  end

  def get_config() do
    Agent.get(__MODULE__, fn(x) -> x end)
  end

  def scrub(message) when is_binary(message) do
    Enum.reduce(get_config(), message, fn(c, acc) ->
      Regex.replace(elem(c, 0), acc, elem(c, 1))
    end)
  end

  defp process_scrub_config() do
    case Application.get_env(:ravenex, :scrubbers) do
      nil ->
        []
      config ->
        Enum.map(config, fn(c) ->
          { Regex.compile!(elem(c, 0), "i"), elem(c, 1) }
        end)
    end
  end
end
