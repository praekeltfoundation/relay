defmodule Relay.Marathon.Supervisor do
  @moduledoc """
  The Supervisor for Relay.Marathon processes.
  """

  use Supervisor

  alias Relay.Marathon

  @doc """
  Starts a new Supervisor.
  """
  def start_link(arg, options \\ []) do
    options = Keyword.put_new(options, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, arg, options)
  end

  def init(_opts) do
    children = [
      {Marathon.Store, [name: Marathon.Store]},
      {Marathon, [name: Marathon]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
