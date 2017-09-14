defmodule Ravenex.LoggerParser do
  @stacktrace_regex ~r/^\s*(?<filename>\([^()]+\)\s+[^:]+):(?<lineno>\d+):(?<function>.*)/m
  @type_regex ~r/^\s*\*\*\s*\((?<type>[^()]+)\)/m
  @exception_header_regex ~r/an exception was raised:/

  def parse(msg) do
    type = Regex.named_captures(@type_regex, msg)["type"]

    messages = Enum.filter_map String.split(msg, "\n"), &(!Regex.match?(@stacktrace_regex, &1) && !Regex.match?(@exception_header_regex, &1)), fn(lineno) ->
      Regex.replace(@type_regex, lineno, "")
    end

    backtrace = Enum.filter_map String.split(msg, "\n"), &(Regex.match?(@stacktrace_regex, &1)), fn(lineno) ->
      hash = Regex.named_captures(@stacktrace_regex, lineno)
      { lineno, _ } = Integer.parse(hash["lineno"])
      %{ hash | "lineno" => lineno }
    end

    %{
      type: type,
      message: MessageScrubber.scrub(Enum.join(messages, "\n")),
      backtrace: backtrace
    }
  end
end
