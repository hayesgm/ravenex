defmodule Ravenex.LoggerParserTest do
  use ExUnit.Case

  setup_all do
    if Process.whereis(RavenexSupervisor) == nil do
      Application.put_env(:ravenex, :scrubbers, nil)
      RavenexSupervisor.start_link([max_restarts: 20])
    end
    :ok
  end

  test "should parse exception from logs" do
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

    result = %{
      backtrace: [
        %{"filename" => "(ecto) lib/ecto/repo/queryable.ex", "function" => " Ecto.Repo.Queryable.one!/4", "lineno" => 57},
        %{"filename" => "(test) web/channels/game_channel.ex", "function" => " Test.GameChannel.join/3", "lineno" => 15},
        %{"filename" => "(phoenix) lib/phoenix/channel/server.ex", "function" => " Phoenix.Channel.Server.init/1", "lineno" => 154},
        %{"filename" => "(stdlib) gen_server.erl", "function" => " :gen_server.init_it/6", "lineno" => 328},
        %{"filename" => "(stdlib) proc_lib.erl", "function" => " :proc_lib.init_p_do_apply/3", "lineno" => 239}
      ],
      message: " expected at least one result but got none in query:\n\nfrom g in Test.Game,\n  where: g.id == ^\"d8fe9f04-8fda-4d8f-9473-67ba94dc9458\"\n\n",
      type: "Ecto.NoResultsError"
    }

    assert Ravenex.LoggerParser.parse(exception) == result
  end
end
