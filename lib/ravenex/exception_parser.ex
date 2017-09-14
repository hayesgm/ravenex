defmodule Ravenex.ExceptionParser do
  def parse(exception) do
    %{
      type: exception.__struct__,
      message: MessageScrubber.scrub(Exception.message(exception)),
      backtrace: stacktrace(System.stacktrace)
    }
  end

  defp stacktrace(stacktrace) do
    Enum.map stacktrace, fn
      ({ module, function, args, [] }) ->
        %{
          filename: "unknown",
          lineno: 0,
          function: "#{ module }.#{ function }#{ args(args) }"
        }
      ({ module, function, args, [file: file, line: line_number] }) ->
        %{
          filename: "(#{module}) #{List.to_string(file)}",
          lineno: line_number,
          function: "#{function}#{args(args)}"
        }
    end
  end

  defp args(args) when is_integer(args) do
    "/#{args}"
  end
  defp args(args) when is_list(args) do
    "(#{args
        |> Enum.map(&(inspect(&1)))
        |> Enum.join(", ")})"
  end
end
