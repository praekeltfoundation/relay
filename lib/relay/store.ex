defmodule Relay.Store.Macros do
  defmodule StructAccess do
    defmacro __using__([]) do
      quote do
        @behaviour Access

        def fetch(term, key), do: Map.fetch(term, key)

        def get(term, key, default), do: Map.get(term, key, default)

        def get_and_update(data, key, function),
          do: Map.get_and_update(data, key, function)

        def pop(data, key), do: Map.pop(data, key)
      end
    end
  end
end

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

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  defmodule Resources do
    use Relay.Store.Macros.StructAccess

    defstruct version_info: "", resources: []
    @type t :: %__MODULE__{
      version_info: String.t,
      resources: [Cluster.t | ClusterLoadAssignment.t | Listener.t | RouteConfiguration.t],
    }
  end

  defmodule State do
    use Relay.Store.Macros.StructAccess

    defstruct resources: %{}, subscribers: %{}
    @type t :: %__MODULE__{
      resources: %{Relay.Store.discovery_service => Resources.t},
      # No way to type the elements of MapSet
      subscribers: %{Relay.Store.discovery_service => MapSet.t},
    }

    def discovery_service_map(initial_value) do
      Relay.Store.discovery_services()
      |> Enum.map(&{&1, initial_value})
      |> Map.new()
    end

    def new() do
      %__MODULE__{
        resources: discovery_service_map(%Resources{}),
        subscribers: discovery_service_map(%MapSet{}),
      }
    end
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

  @spec init(:ok) :: {:ok, State.t}
  def init(:ok) do
    {:ok, State.new()}
  end

  defp notify_subscribers(subscribers, xds, version_info, resources),
    do: Enum.each(subscribers, &notify_subscriber(&1, xds, version_info, resources))

  defp notify_subscriber(subscriber, xds, version_info, resources),
    do: send(subscriber, {xds, version_info, resources})

  defp update_subscribers(state, xds, update_fun),
    do: update_in(state, [:subscribers, xds], update_fun)

  def handle_call({:subscribe, xds, pid}, _from, state) do
    resources = Map.get(state.resources, xds)
    new_state = update_subscribers(state, xds, &MapSet.put(&1, pid))

    # Send the current state to the new subscriber
    notify_subscriber(pid, xds, resources.version_info, resources.resources)

    {:reply, :ok, new_state}
  end

  def handle_call({:unsubscribe, xds, pid}, _from, state) do
    new_state = update_subscribers(state, xds, &MapSet.delete(&1, pid))
    {:reply, :ok, new_state}
  end

  def handle_call({:update, xds, version_info, resources}, _from, state) do
    new_state =
      update_in(state, [:resources, xds], fn xds_resources ->
        if xds_resources.version_info < version_info do
          notify_subscribers(get_in(state, [:subscribers, xds]), xds, version_info, resources)
          %{xds_resources | version_info: version_info, resources: resources}
        else
          xds_resources
        end
      end)

    {:reply, :ok, new_state}
  end

  # For testing only
  def handle_call({:_get_resources, xds}, _from, state),
    do: {:reply, {:ok, Map.get(state.resources, xds)}, state}
  def handle_call({:_get_subscribers, xds}, _from, state),
    do: {:reply, {:ok, Map.get(state.subscribers, xds)}, state}
end
