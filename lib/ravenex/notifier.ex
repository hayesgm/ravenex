defmodule Ravenex.Notifier do
  use HTTPoison.Base

  @sentry_version 5
  quote do
    unquote(@sentry_client "raven-elixir/#{Mix.Project.config[:version]}")
  end
  @logger "Ravenex"
  @sdk %{
    name: "Ravenex",
    version: Ravenex.Mixfile.project[:version]
  }

  def notify(error, options \\ []) do
    case get_dsn do
      dsn when is_bitstring(dsn) ->
        build_notification(error, options)
        |> send_notification(dsn |> parse_dsn)
      :error -> :error
    end
  end

  def build_notification(error, options \\ []) do
    # TODO: culprit?

    %{
      event_id: UUID.uuid4(:hex),
      message: error[:message],
      tags: Application.get_env(:ravenex, :tags, %{}),
      server_name: :net_adm.localhost |> to_string,
      timestamp: iso8601_timestamp,
      environment: Application.get_env(:ravenex, :environment, nil),
      platform: Keyword.get(options, :platform, "other"),
      level: Keyword.get(options, :level, Application.get_env(:ravenex, :logger_level, "error")),
      extra: Keyword.get(options, :context, %{}),
    }
    |> add_logger()
    |> add_sdk()
    |> add_device()
    |> add_error(error)
    |> add_extra(:session, Keyword.get(options, :session))
    |> add_extra(:params, Keyword.get(options, :params))
    |> add_extra(:path, Keyword.get(options, :path))
    |> add_extra(:method, Keyword.get(options, :method))
    |> add_extra(:remote_ip, Keyword.get(options, :remote_ip))
    |> add_extra(:headers, Keyword.get(options, :headers))
    |> add_extra(:cookies, Keyword.get(options, :cookies))
  end

  def send_notification(payload, {endpoint, public_key, private_key}) do
    headers = [
      {"User-Agent", @sentry_client},
      {"X-Sentry-Auth", authorization_header(public_key, private_key)},
    ]

    encoded_payload = Poison.encode!(payload)

    post(endpoint, encoded_payload, headers)
  end

  defp add_logger(payload) do
    payload |> Dict.put(:logger, @logger)
  end

  defp add_sdk(payload) do
    payload |> Dict.put(:sdk, @sdk)
  end

  defp add_device(payload) do
    # TODO: Add device data
    payload |> Dict.put(:device, %{})
  end

  defp add_error(payload, error) do
    exception = %{
      type: error[:type],
      value: error[:message]
    }
    |> add_stacktrace(error[:backtrace])

    payload |> Dict.put(:exception, [exception])
  end

  defp add_stacktrace(exception, nil), do: exception
  defp add_stacktrace(exception, stacktrace) do
    Dict.put(exception, :stacktrace, %{
      frames: stacktrace
    })
  end

  defp add_extra(payload, _key, nil), do: payload
  defp add_extra(payload, key, value) do
    extra = Dict.get(payload, :extra)
    payload |> Dict.put(:extra, Dict.put(extra, key, value))
  end

  def get_dsn do
    case Application.get_env(:ravenex, :dsn) do
      dsn when is_bitstring(dsn) ->
        dsn
      {:system, system_var} ->
        case System.get_env(system_var) do
          dsn when is_bitstring(dsn) ->
            dsn
          _ -> :error
        end
      _ -> :error
    end
  end

  @doc """
  Parses a Sentry DSN which is simply a URI
  """
  defp parse_dsn(dsn) do
    # {PROTOCOL}://{PUBLIC_KEY}:{SECRET_KEY}@{HOST}/{PATH}{PROJECT_ID}
    %URI{userinfo: userinfo, host: host, path: path, scheme: protocol} = URI.parse(dsn)
    [public_key, secret_key] = userinfo |> String.split(":", parts: 2)
    {project_id, _} = path |> String.slice(1..-1) |> Integer.parse
    endpoint = "#{protocol}://#{host}/api/#{project_id}/store/"
    {endpoint, public_key, secret_key}
  end

  @doc """
  Generates a Sentry API authorization header.
  """
  def authorization_header(public_key, secret_key, timestamp \\ nil) do
    # X-Sentry-Auth: Sentry sentry_version=5,
    # sentry_client=<client version, arbitrary>,
    # sentry_timestamp=<current timestamp>,
    # sentry_key=<public api key>,
    # sentry_secret=<secret api key>
    unless timestamp do
      timestamp = unix_timestamp
    end
    "Sentry sentry_version=#{@sentry_version}, sentry_client=#{@sentry_client}, sentry_timestamp=#{timestamp}, sentry_key=#{public_key}, sentry_secret=#{secret_key}"
  end

  @doc """
  Get unix epoch timestamp
  """
  defp unix_timestamp do
    {mega, sec, _micro} = :os.timestamp()
    mega * (1000000 + sec)
  end

  @doc """
  Get current timestamp in iso8601
  """
  defp iso8601_timestamp do
    [year, month, day, hour, minute, second] = 
      :calendar.universal_time 
      |> Tuple.to_list 
      |> Enum.map(&Tuple.to_list(&1)) 
      |> List.flatten 
      |> Enum.map(&to_string(&1)) 
      |> Enum.map(&String.rjust(&1, 2, ?0))
    "#{year}-#{month}-#{day}T#{hour}:#{minute}:#{second}"
  end
end
