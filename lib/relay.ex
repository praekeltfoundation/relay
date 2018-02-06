defmodule Relay do
  @moduledoc """
  Documentation for Relay.
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    services = [
      Relay.Server.ListenerDiscoveryService,
      Relay.Server.RouteDiscoveryService,
      Relay.Server.ClusterDiscoveryService,
      Relay.Server.EndpointDiscoveryService,
    ]
    children = [
      supervisor(GRPC.Server.Supervisor, [{services, 5000}])
    ]

    opts = [strategy: :one_for_one, name: Relay]
    Supervisor.start_link(children, opts)
  end

end
