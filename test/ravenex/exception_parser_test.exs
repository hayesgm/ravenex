defmodule Ravenex.ExceptionParserTest do
  use ExUnit.Case

  test "should parse exception" do

    exception = try do
      IO.inspect("test",[],"")
    rescue
      e -> e
    end

    assert %{
      backtrace: [
        %{filename: "(Elixir.IO) lib/io.ex", function: "inspect(\"test\", [], \"\")", lineno: lineno1},
        %{filename: "(Elixir.Ravenex.ExceptionParserTest) test/ravenex/exception_parser_test.exs", function: "test should parse exception/1", lineno: lineno2},
        %{filename: "(Elixir.ExUnit.Runner) lib/ex_unit/runner.ex", function: "exec_test/1", lineno: _}, %{filename: "(timer) timer.erl", function: "tc/1", lineno: lineno3},
        %{filename: "(Elixir.ExUnit.Runner) lib/ex_unit/runner.ex", function: "-spawn_test/3-fun-1-/3", lineno: lineno4}
      ],
      message: "no function clause matching in IO.inspect/3",
      type: FunctionClauseError
    } = Ravenex.ExceptionParser.parse(exception)
    assert is_number(lineno1) and lineno1 > 0
    assert is_number(lineno2) and lineno2 > 0
    assert is_number(lineno3) and lineno3 > 0
    assert is_number(lineno4) and lineno4 > 0
  end
end
