defmodule Relay.Demo.Marathon do
  alias Relay.Store
  alias Relay.Marathon.{Adapter, App, Task}

  @demo_app %App{
    id: "/demo",
    labels: %{
      "HAPROXY_0_REDIRECT_TO_HTTPS" => "false",
      "HAPROXY_0_VHOST" => "example.com",
      "HAPROXY_GROUP" => "external",
      "MARATHON_ACME_0_DOMAIN" => "example.com"
    },
    networking_mode: :"container/bridge",
    ports_list: [80],
    port_indices_in_group: [0],
    version: "2017-11-08T15:06:31.066Z"
  }

  @demo_task %Task{
    address: "127.0.0.1",
    app_id: "/demo",
    id: "demo.be753491-1325-11e8-b5d6-4686525b33db",
    ports: [8081],
    version: "2017-11-09T08:43:59.890Z"
  }

  use GenServer

  defmodule State do
    defstruct delay: 1_000, version: 1
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def update_state(), do: GenServer.call(__MODULE__, :update_state)

  # Callbacks

  def init(_args) do
    # TODO: Make delay configurable.
    send(self(), :scheduled_update)
    {:ok, %State{}}
  end

  def handle_call(:update_state, _from, state) do
    {:reply, :ok, update_state(state)}
  end

  def handle_info(:scheduled_update, state) do
    Process.send_after(self(), :scheduled_update, state.delay)
    {:noreply, update_state(state)}
  end

  # Internals

  defp update_state(state) do
    v = "#{state.version}"
    Store.update(Store, :cds, v, clusters())
    Store.update(Store, :rds, v, routes())
    Store.update(Store, :eds, v, endpoints())
    %{state | version: state.version + 1}
  end

  def clusters do
    Adapter.app_clusters(@demo_app)
  end

  def routes do
    Adapter.apps_route_configurations([@demo_app])
  end

  def endpoints do
    Adapter.app_cluster_load_assignments(@demo_app, [@demo_task])
  end
end
