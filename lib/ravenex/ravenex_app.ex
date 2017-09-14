defmodule RavenexApp do
  def start(_type, _args) do
    RavenexSupervisor.start_link()
  end
end
