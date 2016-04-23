defmodule Ravenex do
  def notify(exception, options \\ []) do
    Ravenex.ExceptionParser.parse(exception) |> Ravenex.Notifier.notify(options)
  end
end
