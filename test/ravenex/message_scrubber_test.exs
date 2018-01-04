defmodule MessageScrubberTest do
  use ExUnit.Case

  setup_all do
    Supervisor.stop(RavenexSupervisor)
    # Need to set max_restarts, otherwise the supervisor will be shutdown
    # because of the numerous stop/start of the MessageScrubber.
    RavenexSupervisor.start_link([max_restarts: 20])
    :ok
  end

  test "Test scrubber with empty rules" do
    Application.put_env(:ravenex, :scrubbers, nil)
    restart_scrubber()
    assert MessageScrubber.get_config() == []
    assert MessageScrubber.scrub("testing") == "testing"
  end

  test "Test single scrubber rule" do
    Application.put_env(:ravenex, :scrubbers, [{"a", "x" }])
    restart_scrubber()
    assert MessageScrubber.scrub("abc") == "xbc"
  end

  test "Test multiple scrubber rules" do
    Application.put_env(:ravenex, :scrubbers, [{"a", "x" }, {"b", ""}])
    restart_scrubber()
    assert MessageScrubber.scrub("abc") == "xc"
  end

  test "LoggerParser.parse should use message scrubber" do
    exception = """
      an exception was raised:
        ** (Ecto.NoResultsError) This error has password: pass
    Another password: pass2 should be scrubbed
    """
    Application.put_env(:ravenex, :scrubbers, [{"password: .+?(\n| )", "password: SCRUBBED\\1" }])
    restart_scrubber()
    parsed = Ravenex.LoggerParser.parse(exception)

    assert parsed.message == " This error has password: SCRUBBED\nAnother password: SCRUBBED should be scrubbed\n"
  end

  test "ExceptionParser.parse should use message scrubber" do
    exception = try do
      raise """
       This error has password: pass
      Another password: pass2 should be scrubbed
      """
    rescue
      e -> e
    end

    Application.put_env(:ravenex, :scrubbers, [{"password: .+?(\n| )", "password: SCRUBBED\\1" }])
    restart_scrubber()
    parsed = Ravenex.ExceptionParser.parse(exception)

    assert parsed.message == " This error has password: SCRUBBED\nAnother password: SCRUBBED should be scrubbed\n"
  end

  defp restart_scrubber() do
    Process.whereis(MessageScrubber) |> Agent.stop()

    t = GenRetry.Task.async( fn ->
      case Process.whereis(MessageScrubber) do
        nil -> raise "not done"
        _ -> true
      end
    end, retries: 10, delay: 150 )

    Task.await(t)
  end
end
