defmodule Relay do
  @moduledoc """
  Documentation for Relay.
  """

  use Application

  alias Relay.Supervisor

  def start(_type, _args) do
    Supervisor.start_link({5000}, name: Supervisor)
  end

end
