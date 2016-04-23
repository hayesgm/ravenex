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
            |> Ravenex.Notifier.notify([params: conn.params, session: session])

            reraise exception, System.stacktrace
        end
      end
    end
  end
end
