defmodule Relay.Publisher do
  use GenServer

  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment, Listener, RouteConfiguration}

  # We need both an attribute (so that the list can be used at compile time in
  # guards) and a function (so that the list can be used in tests).
  @discovery_services [:lds, :rds, :cds, :eds]
  def discovery_services, do: @discovery_services

  @type discovery_service :: :lds | :rds | :cds | :eds
  # The dest types supported by Kernel.send/2
  @type subscriber :: pid | port | atom | {atom, node}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  defmodule Resources do
    defstruct version_info: "", resources: [], subscribers: MapSet.new()
    @type t :: %__MODULE__{
      version_info: String.t,
      resources: [Cluster.t | ClusterLoadAssignment.t | Listener.t | RouteConfiguration.t],
      subscribers: %MapSet{} # No way to type the elements of MapSet
    }
  end

  ## Client interface

  defguardp is_xds(xds) when xds in @discovery_services

  @spec subscribe(GenServer.server, discovery_service, subscriber) :: :ok
  def subscribe(server, xds, pid) when is_xds(xds),
    do: GenServer.call(server, {:subscribe, xds, pid})

  @spec unsubscribe(GenServer.server, discovery_service, subscriber) :: :ok
  def unsubscribe(server, xds, pid) when is_xds(xds),
    do: GenServer.call(server, {:unsubscribe, xds, pid})

  @spec update(GenServer.server, :lds, String.t, [Listener.t]) :: :ok
  @spec update(GenServer.server, :rds, String.t, [RouteConfiguration.t]) :: :ok
  @spec update(GenServer.server, :cds, String.t, [Cluster.t]) :: :ok
  @spec update(GenServer.server, :eds, String.t, [ClusterLoadAssignment.t]) :: :ok
  def update(server, xds, version_info, resources) when is_xds(xds),
    do: GenServer.call(server, {:update, xds, version_info, resources})

  ## Server callbacks

  @spec init(:ok) :: {:ok, %{discovery_service => Resources.t}}
  def init(:ok) do
    {:ok, Map.new(Enum.map(@discovery_services, fn xds -> {xds, %Resources{}} end))}
  end

  defp notify_subscribers(subscribers, xds, version_info, resources),
    do: Enum.each(subscribers, &notify_subscriber(&1, xds, version_info, resources))

  defp notify_subscriber(subscriber, xds, version_info, resources),
    do: send(subscriber, {xds, version_info, resources})

  def handle_call({:subscribe, xds, pid}, _from, state) do
    resources = Map.get(state, xds)

    new_subscribers = MapSet.put(resources.subscribers, pid)
    new_state = Map.put(state, xds, %{resources | subscribers: new_subscribers})

    # Send the current state to the new subscriber
    notify_subscriber(pid, xds, resources.version_info, resources.resources)

    {:reply, :ok, new_state}
  end

  def handle_call({:unsubscribe, xds, pid}, _from, state) do
    resources = Map.get(state, xds)

    new_subscribers = MapSet.delete(resources.subscribers, pid)
    new_state = Map.put(state, xds, %{resources | subscribers: new_subscribers})

    {:reply, :ok, new_state}
  end

  def handle_call({:update, xds, version_info, resources}, _from, state) do
    xds_resources = Map.get(state, xds)

    new_state =
      if xds_resources.version_info < version_info do
        notify_subscribers(xds_resources.subscribers, xds, version_info, resources)

        new_resources = %{xds_resources | version_info: version_info, resources: resources}
        Map.put(state, xds, new_resources)
      else
        state
      end

    {:reply, :ok, new_state}
  end

  # For testing only
  def handle_call({:_get_resources, xds}, _from, state),
    do: {:reply, {:ok, Map.get(state, xds)}, state}
end
