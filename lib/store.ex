defmodule Relay.Store do
  use GenServer

  def start_link(arg, opts \\ []) do
    GenServer.start_link(__MODULE__, arg, opts)
  end

  defmodule Resources do
    defstruct version_info: "", resources: [], subscribers: MapSet.new()
  end

  defmodule State do
    defstruct lds: %Resources{}, rds: %Resources{}, cds: %Resources{}, eds: %Resources{}
  end


  ## Client interface

  def subscribe_lds(server, pid), do:
    GenServer.call(server, {:subscribe, :lds, pid})

  def unsubscribe_lds(server, pid), do:
    GenServer.call(server, {:unsubscribe, :lds, pid})

  def update_lds(server, version_info, resources), do:
    GenServer.call(server, {:update, :lds, version_info, resources})

  def subscribe_rds(server, pid), do:
    GenServer.call(server, {:subscribe, :rds, pid})

  def unsubscribe_rds(server, pid), do:
    GenServer.call(server, {:unsubscribe, :rds, pid})

  def update_rds(server, version_info, resources), do:
    GenServer.call(server, {:update, :rds, version_info, resources})

  def subscribe_cds(server, pid), do:
    GenServer.call(server, {:subscribe, :cds, pid})

  def unsubscribe_cds(server, pid), do:
    GenServer.call(server, {:unsubscribe, :cds, pid})

  def update_cds(server, version_info, resources), do:
    GenServer.call(server, {:update, :cds, version_info, resources})

  def subscribe_eds(server, pid), do:
    GenServer.call(server, {:subscribe, :eds, pid})

  def unsubscribe_eds(server, pid), do:
    GenServer.call(server, {:unsubscribe, :eds, pid})

  def update_eds(server, version_info, resources), do:
    GenServer.call(server, {:update, :eds, version_info, resources})


  ## Server callbacks

  def init(:ok) do
    {:ok, %State{}}
  end

  defp subscribe(xds, pid, state) do
    resources = Map.get(state, xds)

    new_subscribers = MapSet.put(resources.subscribers, pid)
    new_state = Map.put(state, xds, %{resources | subscribers: new_subscribers})

    # Return the current state with the subscription request
    {:reply, {:ok, resources.version_info, resources.resources}, new_state}
  end

  defp unsubscribe(xds, pid, state) do
    resources = Map.get(state, xds)

    new_subscribers = MapSet.delete(resources.subscribers, pid)
    new_state = Map.put(state, xds, %{resources | subscribers: new_subscribers})

    {:reply, :ok, new_state}
  end

  defp update(xds, version_info, resources, state) do
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

  defp notify_subscribers(subscribers, xds, version_info, resources), do:
    Enum.each(subscribers, fn l -> send(l, {xds, version_info, resources}) end)

  def handle_call({:subscribe, xds, pid}, _from, state), do:
    subscribe(xds, pid, state)

  def handle_call({:unsubscribe, xds, pid}, _from, state), do:
    unsubscribe(xds, pid, state)

  def handle_call({:update, xds, version_info, resources}, _from, state), do:
    update(xds, version_info, resources, state)

  # For testing only
  def handle_call({:_get_resources, xds}, _from, state), do:
    {:reply, {:ok, Map.get(state, xds)}, state}
end
