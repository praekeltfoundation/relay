defmodule Relay.Supervisor do
  @moduledoc """
  The parent Supervisor for the overall program. Supervises the Publisher
  process as well as the Supervisor for the other processes.
  """

  use Supervisor

  @doc """
  Starts a new Supervisor.
  `port` is the port that the gRPC server should listen on.
  """
  def start_link({addr, port}, options \\ []) do
    options = Keyword.put_new(options, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, {addr, port}, options)
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

    def init({addr, port}) do
      services = [
        Relay.Server.ListenerDiscoveryService,
        Relay.Server.RouteDiscoveryService,
        Relay.Server.ClusterDiscoveryService,
        Relay.Server.EndpointDiscoveryService
      ]

      opts = [adapter: Relay.GRPCAdapter, ip: parse_ip_address(addr)]

      children = [
        {Relay.Demo.Marathon, []},
        {Relay.Demo.Certs, []},
        supervisor(GRPC.Server.Supervisor, [{services, port, opts}])
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end

    @spec parse_ip_address(String.t()) :: :inet.ip_address()
    defp parse_ip_address(addr) do
      {:ok, address} = addr |> String.to_charlist() |> :inet.parse_address()
      address
    end
  end

  def init({addr, port}) do
    children = [
      {Relay.Publisher, [name: Relay.Publisher]},
      {Relay.Resources, [name: Relay.Resources]},
      {FrontendSupervisor, {addr, port}}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
