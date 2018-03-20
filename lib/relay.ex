defmodule Relay do
  @moduledoc """
  Documentation for Relay.
  """

  use Application

  alias Relay.Supervisor

  def start(_type, _args) do
    listen = Application.fetch_env!(:relay, :listen)
    addr = Keyword.get(listen, :address)
    port = Keyword.get(listen, :port)

    Supervisor.start_link({addr, port}, name: Supervisor)
  end

end
