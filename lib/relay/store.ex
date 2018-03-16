defmodule Relay.Store do
  use GenServer

  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment, Listener, RouteConfiguration}

  # We need both an attribute (so that the list can be used at compile time in
  # guards) and a function (so that the list can be used in tests).
  @discovery_services [:lds, :rds, :cds, :eds]
  def discovery_services, do: @discovery_services

  @type discovery_service :: :lds | :rds | :cds | :eds
  # The dest types supported by Kernel.send/2
  @type subscriber :: pid | port | atom | {atom, node}

  @type resources :: [Cluster.t | ClusterLoadAssignment.t | Listener.t | RouteConfiguration.t]

  defmodule State do
    defstruct [:resources, :subscribers]
    @type t :: %__MODULE__{resources: :ets.tab, subscribers: :ets.tab}

    def new() do
      # FIXME: resources are not discovery services.
      %__MODULE__{
        resources: mktable(:resources, Relay.Store.discovery_services(), &{&1, "", []}),
        subscribers: mktable(:subscribers, Relay.Store.discovery_services(), &{&1, %MapSet{}}),
      }
    end

    defp mktable(name, keys, value_fun) do
      tbl = :ets.new(name, [:set, :protected])
      Enum.each(keys, &:ets.insert(tbl, value_fun.(&1)))
      tbl
    end


    # Resources
    def get_resources(state, rtype) do
      [{^rtype, version, resources}] = :ets.lookup(state.resources, rtype)
      {version, resources}
    end

    def update_resources(state, rtype, version, resources) do
      {cur_version, _} = get_resources(state, rtype)
      update = version > cur_version
      if update, do: :ets.insert(state.resources, {rtype, version, resources})
      update
    end

    # Subscribers
    def get_subscribers(state, xds) do
      [{^xds, subs}] = :ets.lookup(state.subscribers, xds)
      subs
    end

    def subscribe(state, xds, pid),
      do: update_subs(state, xds, &MapSet.put(&1, pid))

    def unsubscribe(state, xds, pid),
      do: update_subs(state, xds, &MapSet.delete(&1, pid))

    defp update_subs(state, xds, update_fun) do
      subs = get_subscribers(state, xds)
      :ets.insert(state.subscribers, {xds, update_fun.(subs)})
    end
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
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
  def update(server, xds, version, resources) when is_xds(xds),
    do: GenServer.call(server, {:update, xds, version, resources})

  ## Server callbacks

  @spec init(:ok) :: {:ok, State.t}
  def init(:ok) do
    {:ok, State.new()}
  end

  def handle_call({:subscribe, xds, pid}, _from, state) do
    State.subscribe(state, xds, pid)
    # Send the current state to the new subscriber
    notify_subscribers(state, xds, [pid])
    {:reply, :ok, state}
  end

  def handle_call({:unsubscribe, xds, pid}, _from, state) do
    State.unsubscribe(state, xds, pid)
    {:reply, :ok, state}
  end

  def handle_call({:update, rtype, version, resources}, _from, state) do
    updated = State.update_resources(state, rtype, version, resources)
    if updated, do: notify_subscribers(state, rtype)
    {:reply, :ok, state}
  end

  # For testing only
  def handle_call({:_get_resources, xds}, _from, state),
    do: {:reply, {:ok, State.get_resources(state, xds)}, state}

  def handle_call({:_get_subscribers, xds}, _from, state),
    do: {:reply, {:ok, State.get_subscribers(state, xds)}, state}

  # Internals

  defp notify_subscribers(state, xds),
    do: notify_subscribers(state, xds, State.get_subscribers(state, xds))

  defp notify_subscribers(state, xds, subs) do
    {version, resources} = build_xds_resources(state, xds)
    Enum.each(subs, &notify_subscriber(&1, xds, version, resources))
  end

  defp notify_subscriber(subscriber, xds, version, resources),
    do: send(subscriber, {xds, version, resources})

  defp build_xds_resources(state, xds) do
    # FIXME: Build xds resources from stored resources.
    State.get_resources(state, xds)
  end
end
