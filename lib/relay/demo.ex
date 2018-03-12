defmodule Relay.Demo do
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
    Store.update(Store, :lds, v, listeners())
    Store.update(Store, :rds, v, routes())
    Store.update(Store, :eds, v, endpoints())
    %{state | version: state.version + 1}
  end

  defp socket_address(address, port) do
    alias Envoy.Api.V2.Core.{Address, SocketAddress}
    sock = SocketAddress.new(address: address, port_specifier: {:port_value, port})
    Address.new(address: {:socket_address, sock})
  end

  defp own_api_config_source do
    alias Envoy.Api.V2.Core.{ApiConfigSource, ConfigSource, GrpcService}
    ConfigSource.new(config_source_specifier: {:api_config_source, ApiConfigSource.new(
      api_type: ApiConfigSource.ApiType.value(:GRPC),
      # TODO: Make our cluster name configurable--this must match the cluster
      # name in bootstrap.yaml
      # TODO: I don't understand what grpc_services is for when there is a
      # `cluster_names`. `cluster_names` is required.
      cluster_names: ["xds_cluster"],
      grpc_services: [
        GrpcService.new(target_specifier:
          {:envoy_grpc, GrpcService.EnvoyGrpc.new(cluster_name: "xds_cluster")})
      ]
    )})
  end

  def clusters do
    Adapter.app_clusters(@demo_app, own_api_config_source())
  end

  defp router_filter do
    alias Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpFilter
    alias Envoy.Config.Filter.Http.Router.V2.Router
    alias Envoy.Config.Filter.Accesslog.V2.{AccessLog, FileAccessLog}
    import Relay.ProtobufUtil
    HttpFilter.new(
      name: "envoy.router",
      config: mkstruct(Router.new(upstream_log: [
        AccessLog.new(
          name: "envoy.file_access_log",
          config: mkstruct(FileAccessLog.new(path: "upstream.log")))
      ]))
    )
  end

  defp default_http_conn_manager_filter(name) do
    alias Envoy.Api.V2.Listener.Filter
    alias Envoy.Config.Filter.Network.HttpConnectionManager.V2.{HttpConnectionManager, Rds}
    import Relay.ProtobufUtil
    Filter.new(
      name: "envoy.http_connection_manager",
      config: mkstruct(HttpConnectionManager.new(
        codec_type: HttpConnectionManager.CodecType.value(:AUTO),
        route_specifier: {:rds, Rds.new(
          config_source: own_api_config_source(), route_config_name: "http")},
        stat_prefix: name,
        http_filters: [router_filter()]))
      )
  end

  def listeners do
    alias Envoy.Api.V2.Listener

    [
      Listener.new(
        name: "http",
        address: socket_address("0.0.0.0", 8080),
        filter_chains: [
          Listener.FilterChain.new(
            filter_chain_match: Listener.FilterChainMatch.new(),
            filters: [default_http_conn_manager_filter("http")]
          ),
        ]
      )
    ]
  end

  def routes do
    alias Envoy.Api.V2.RouteConfiguration
    [
      RouteConfiguration.new(
        name: "http",
        virtual_hosts: Adapter.app_virtual_hosts(:http, @demo_app)
      )
    ]
  end

  def endpoints do
    Adapter.app_cluster_load_assignments(@demo_app, [@demo_task])
  end
end
