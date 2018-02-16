defmodule Relay do
  @moduledoc """
  Documentation for Relay.
  """

  use Application

  alias Relay.Supervisor

  def start(_type, _args) do
    port = Application.get_env(:relay, :port, 5000)
    Supervisor.start_link({port}, name: Supervisor)
  end

end
