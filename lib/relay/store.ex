defmodule Relay.Store do
  use GenServer

  # We need both an attribute (so that the list can be used at compile time in
  # guards) and a function (so that the list can be used in tests).
  @discovery_services [:lds, :rds, :cds, :eds]
  def discovery_services, do: @discovery_services

  @type discovery_service :: :lds | :rds | :cds | :eds


  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  defmodule Resources do
    defstruct version_info: "", resources: [], subscribers: MapSet.new()
  end


  ## Client interface

  defguardp is_xds(xds) when xds in @discovery_services

  @spec subscribe(identifier | atom, discovery_service, pid) :: :ok
  def subscribe(server, xds, pid) when is_xds(xds), do:
    GenServer.call(server, {:subscribe, xds, pid})

  @spec unsubscribe(identifier | atom, discovery_service, pid) :: :ok
  def unsubscribe(server, xds, pid) when is_xds(xds), do:
    GenServer.call(server, {:unsubscribe, xds, pid})

  @spec update(identifier | atom, :lds, String.t, [Envoy.Api.V2.Listener.t]) :: :ok
  @spec update(identifier | atom, :rds, String.t, [Envoy.Api.V2.RouteConfiguration.t]) :: :ok
  @spec update(identifier | atom, :cds, String.t, [Envoy.Api.V2.Cluster.t]) :: :ok
  @spec update(identifier | atom, :eds, String.t, [Envoy.Api.V2.ClusterLoadAssignment.t]) :: :ok
  def update(server, xds, version_info, resources) when is_xds(xds), do:
    GenServer.call(server, {:update, xds, version_info, resources})


  ## Server callbacks

  def init(:ok) do
    {:ok, Map.new(Enum.map(@discovery_services, fn xds -> {xds, %Resources{}} end))}
  end

  defp subscribe_impl(xds, pid, state) do
    resources = Map.get(state, xds)

    new_subscribers = MapSet.put(resources.subscribers, pid)
    new_state = Map.put(state, xds, %{resources | subscribers: new_subscribers})

    # Send the current state to the new subscriber
    notify_subscriber(pid, xds, resources.version_info, resources.resources)

    {:reply, :ok, new_state}
  end

  defp unsubscribe_impl(xds, pid, state) do
    resources = Map.get(state, xds)

    new_subscribers = MapSet.delete(resources.subscribers, pid)
    new_state = Map.put(state, xds, %{resources | subscribers: new_subscribers})

    {:reply, :ok, new_state}
  end

  defp update_impl(xds, version_info, resources, state) do
    xds_resources = Map.get(state, xds)
    new_state = if xds_resources.version_info < version_info do
      notify_subscribers(xds_resources.subscribers, xds, version_info, resources)

      new_resources = %{xds_resources | version_info: version_info, resources: resources}
      Map.put(state, xds, new_resources)
    else
      state
    end
    {:reply, :ok, new_state}
  end

  defp notify_subscribers(subscribers, xds, version_info, resources),
    do: Enum.each(subscribers, &notify_subscriber(&1, xds, version_info, resources))

  defp notify_subscriber(subscriber, xds, version_info, resources),
    do: send(subscriber, {xds, version_info, resources})

  def handle_call({:subscribe, xds, pid}, _from, state), do:
    subscribe_impl(xds, pid, state)

  def handle_call({:unsubscribe, xds, pid}, _from, state), do:
    unsubscribe_impl(xds, pid, state)

  def handle_call({:update, xds, version_info, resources}, _from, state), do:
    update_impl(xds, version_info, resources, state)

  # For testing only
  def handle_call({:_get_resources, xds}, _from, state), do:
    {:reply, {:ok, Map.get(state, xds)}, state}
end
