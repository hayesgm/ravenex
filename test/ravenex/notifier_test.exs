defmodule Ravenex.NotifierTest do
  use ExUnit.Case

  alias Ravenex.ExceptionParser
  alias Ravenex.LoggerParser
  alias Ravenex.Notifier

  test "should correctly serialize exception" do
    exception = try do
      IO.inspect("test",[],"")
    rescue
      e -> e
    end

    error = ExceptionParser.parse(exception)

    notification = Notifier.build_notification(error)

    assert notification[:event_id] != nil
    assert notification[:device] == %{}
    assert notification[:environment] == nil
    assert List.first(notification[:exception])[:type] == FunctionClauseError
    assert List.first(notification[:exception])[:value] == "no function clause matching in IO.inspect/3"
    assert [
        %{filename: "(Elixir.IO) lib/io.ex", function: "inspect(\"test\", [], \"\")", lineno: lineno1},
        %{filename: "(Elixir.Ravenex.NotifierTest) test/ravenex/notifier_test.exs",
          function: "test should correctly serialize exception/1", lineno: lineno2},
        %{filename: "(Elixir.ExUnit.Runner) lib/ex_unit/runner.ex", function: "exec_test/1", lineno: lineno3},
        %{filename: "(timer) timer.erl", function: "tc/1", lineno: lineno4},
        %{filename: "(Elixir.ExUnit.Runner) lib/ex_unit/runner.ex", function: "-spawn_test/3-fun-1-/3", lineno: lineno5}] = List.first(notification[:exception])[:stacktrace][:frames]
    assert is_number(lineno1) and lineno1 > 0
    assert is_number(lineno2) and lineno2 > 0
    assert is_number(lineno3) and lineno3 > 0
    assert is_number(lineno4) and lineno4 > 0
    assert is_number(lineno5) and lineno5 > 0
    assert notification[:extra] == %{}
    assert notification[:level] == "error"
    assert notification[:logger] == "Ravenex"
    assert notification[:message] == "no function clause matching in IO.inspect/3"
    assert notification[:platform] == "other"
    assert notification[:sdk] == %{name: "Ravenex", version: Ravenex.Mixfile.project[:version]}
    assert notification[:server_name] != nil
    assert notification[:tags] == %{}
    assert notification[:timestamp] != nil
  end

  test "should correctly serialize log" do
    exception = """
      an exception was raised:
        ** (Ecto.NoResultsError) expected at least one result but got none in query:

      from g in Test.Game,
        where: g.id == ^"d8fe9f04-8fda-4d8f-9473-67ba94dc9458"

              (ecto) lib/ecto/repo/queryable.ex:57: Ecto.Repo.Queryable.one!/4
              (test) web/channels/game_channel.ex:15: Test.GameChannel.join/3
              (phoenix) lib/phoenix/channel/server.ex:154: Phoenix.Channel.Server.init/1
              (stdlib) gen_server.erl:328: :gen_server.init_it/6
              (stdlib) proc_lib.erl:239: :proc_lib.init_p_do_apply/3
      """

    error = LoggerParser.parse(exception)

    notification = Notifier.build_notification(error)

    assert notification[:event_id] != nil
    assert notification[:device] == %{}
    assert notification[:environment] == nil
    assert List.first(notification[:exception])[:type] == "Ecto.NoResultsError"
    assert List.first(notification[:exception])[:value] == " expected at least one result but got none in query:\n\nfrom g in Test.Game,\n  where: g.id == ^\"d8fe9f04-8fda-4d8f-9473-67ba94dc9458\"\n\n"
    assert [
      %{"filename" => "(ecto) lib/ecto/repo/queryable.ex", "function" => " Ecto.Repo.Queryable.one!/4", "lineno" => lineno1},
      %{"filename" => "(test) web/channels/game_channel.ex", "function" => " Test.GameChannel.join/3", "lineno" => lineno2},
      %{"filename" => "(phoenix) lib/phoenix/channel/server.ex", "function" => " Phoenix.Channel.Server.init/1", "lineno" => lineno3},
      %{"filename" => "(stdlib) gen_server.erl", "function" => " :gen_server.init_it/6", "lineno" => lineno4},
      %{"filename" => "(stdlib) proc_lib.erl", "function" => " :proc_lib.init_p_do_apply/3", "lineno" => lineno5}] = List.first(notification[:exception])[:stacktrace][:frames]
    assert is_number(lineno1) and lineno1 > 0
    assert is_number(lineno2) and lineno2 > 0
    assert is_number(lineno3) and lineno3 > 0
    assert is_number(lineno4) and lineno4 > 0
    assert is_number(lineno5) and lineno5 > 0
    assert notification[:extra] == %{}
    assert notification[:level] == "error"
    assert notification[:logger] == "Ravenex"
    assert notification[:message] == " expected at least one result but got none in query:\n\nfrom g in Test.Game,\n  where: g.id == ^\"d8fe9f04-8fda-4d8f-9473-67ba94dc9458\"\n\n"
    assert notification[:platform] == "other"
    assert notification[:sdk] == %{name: "Ravenex", version: Ravenex.Mixfile.project[:version]}
    assert notification[:server_name] != nil
    assert notification[:tags] == %{}
    assert notification[:timestamp] != nil
  end

  test "with session" do
    error = %{
      type: "Type",
      message: "Message",
      backtrace: []
    }

    notification = Notifier.build_notification(error, session: %{a: "b"})

    assert notification[:extra] == %{session: %{a: "b"}}
  end

  test "with session and params" do
    error = %{
      type: "Type",
      message: "Message",
      backtrace: []
    }

    notification = Notifier.build_notification(error, session: %{a: "b"}, params: %{c: "d"})

    assert notification[:extra] == %{params: %{c: "d"}, session: %{a: "b"}}
  end

  test "with backtrace" do

  end

  test "get dsn" do
    original = Application.get_env(:ravenex, :dsn)

    try do
      # Test string
      Application.put_env(:ravenex, :dsn, "string")
      assert Notifier.get_dsn == "string"

      # Test system var - missing
      Application.put_env(:ravenex, :dsn, {:system, "RAVENEX_TEST_VARIABLE"})
      assert Notifier.get_dsn == :error

      # Test system var - set
      System.put_env("RAVENEX_TEST_VARIABLE", "123")
      assert Notifier.get_dsn == "123"

      # Test otherwise
      Application.put_env(:ravenex, :dsn, :cats)
      assert Notifier.get_dsn == :error
    after
      Application.put_env(:ravenex, :dsn, original)
    end
  end

  test "ignore, when a list" do
    Application.put_env(:ravenex, :dsn, "https://xxx:yyy@app.getsentry.com/12345")

    ignore = Application.get_env(:ravenex, :ignore)
    Application.put_env(:ravenex, :ignore, [FunctionClauseError])

    try do
      error = try do
        IO.inspect("test", [], "")
      rescue
        e -> e
      end

      parsed_error = ExceptionParser.parse(error)
      res = Notifier.notify(parsed_error, [])

      assert res == :ok
    after
      Application.put_env(:ravenex, :ignore, ignore)
    end
  end

  test "ignore, when a function" do
    Application.put_env(:ravenex, :dsn, "https://xxx:yyy@app.getsentry.com/12345")

    ignore = Application.get_env(:ravenex, :ignore)
    Application.put_env(:ravenex, :ignore, fn(error) -> error.type == FunctionClauseError end)

    try do
      error = try do
        IO.inspect("test", [], "")
      rescue
        e -> e
      end

      parsed_error = ExceptionParser.parse(error)
      res = Notifier.notify(parsed_error, [])

      assert res == :ok
    after
      Application.put_env(:ravenex, :ignore, ignore)
    end
  end
end
