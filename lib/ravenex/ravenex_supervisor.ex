defmodule RavenexSupervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: RavenexSupervisor)
  end

  def init(opts) do
    children = [
      worker(MessageScrubber, [])
    ]

    supervise(children, [strategy: :one_for_one] ++ opts)
  end
end
