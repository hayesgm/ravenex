defmodule Ravenex.ExceptionParserTest do
  use ExUnit.Case

  test "should parse exception" do

    exception = try do
      IO.inspect("test",[],"")
    rescue
      e -> e
    end

    result = %{
      backtrace: [
        %{filename: "(Elixir.IO) lib/io.ex", function: "inspect(\"test\", [], \"\")", lineno: 258},
        %{filename: "(Elixir.Ravenex.ExceptionParserTest) test/ravenex/exception_parser_test.exs", function: "test should parse exception/1", lineno: 7},
        %{filename: "(Elixir.ExUnit.Runner) lib/ex_unit/runner.ex", function: "exec_test/1", lineno: 296}, %{filename: "(timer) timer.erl", function: "tc/1", lineno: 166},
        %{filename: "(Elixir.ExUnit.Runner) lib/ex_unit/runner.ex", function: "-spawn_test/3-fun-1-/3", lineno: 246}
      ],
      message: "no function clause matching in IO.inspect/3",
      type: FunctionClauseError
    }

    %{
      backtrace: [],
      message: "no function clause matching in IO.inspect/3",
      type: FunctionClauseError
    }

    assert Ravenex.ExceptionParser.parse(exception) == result
  end
end
