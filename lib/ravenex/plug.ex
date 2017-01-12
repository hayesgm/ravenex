defmodule Ravenex.Plug do
  defmacro __using__(_env) do
    quote location: :keep do
      @before_compile Ravenex.Plug
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      defoverridable [call: 2]

      def call(conn, opts) do
        try do
          super(conn, opts)
        rescue
          exception ->
            session = Map.get(conn.private, :plug_session)

            Ravenex.ExceptionParser.parse(exception)
            |> Ravenex.Notifier.notify([
              path: conn.request_path,
              method: conn.method,
              params: conn.params,
              session: session,
              remote_ip: case :inet.ntoa(conn.remote_ip) do
                {:error, :einval} -> nil
                ip -> to_string(ip)
              end,
              headers: (for {k, v} <- conn.req_headers, do: "#{k}: #{v}"),
              cookies: case conn.req_cookies do
                %Plug.Conn.Unfetched{} -> nil
                els -> els
              end])

            reraise exception, System.stacktrace
        end
      end
    end
  end
end
