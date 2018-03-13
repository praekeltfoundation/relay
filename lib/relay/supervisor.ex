defmodule Relay.Supervisor do
  @moduledoc """
  The parent Supervisor for the overall program. Supervises the Store
  process as well as the Supervisor for the other processes.
  """

  use Supervisor

  @doc """
  Starts a new Supervisor.
  `port` is the port that the gRPC server should listen on.
  """
  def start_link({port}, options \\ []) do
    options = Keyword.put_new(options, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, {port}, options)
  end

  defmodule FrontendSupervisor do
    @moduledoc """
    A Supervisor to manage the `Demo` and `GRPC.Server`s which do not have
    any dependent processes and so can be restarted independently.
    """
    use Supervisor

    def start_link(arg, options \\ []) do
      options = Keyword.put_new(options, :name, __MODULE__)
      Supervisor.start_link(__MODULE__, arg, options)
    end

    def init({port}) do
      services = [
        Relay.Server.ListenerDiscoveryService,
        Relay.Server.RouteDiscoveryService,
        Relay.Server.ClusterDiscoveryService,
        Relay.Server.EndpointDiscoveryService,
      ]
      opts = [adapter: Relay.GRPCAdapter]
      children = [
        {Relay.Demo.Marathon, []},
        {Relay.Demo.Certs, []},
        supervisor(GRPC.Server.Supervisor, [{services, port, opts}])
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  def init({port}) do
    children = [
      {Relay.Store, [name: Relay.Store]},
      {FrontendSupervisor, {port}},
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
