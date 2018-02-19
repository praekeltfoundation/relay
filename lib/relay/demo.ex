defmodule Relay.Demo do
  alias Relay.Store

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

  def clusters do
    alias Envoy.Api.V2.Cluster
    alias Envoy.Api.V2.Core.Http1ProtocolOptions
    alias Google.Protobuf.Duration

    [
      Cluster.new(
        name: "demo",
        type: Cluster.DiscoveryType.value(:STATIC),
        hosts: [socket_address("127.0.0.1", 8081)],
        connect_timeout: Duration.new(seconds: 30),
        lb_policy: Cluster.LbPolicy.value(:ROUND_ROBIN),
        health_checks: [],
        http_protocol_options: Http1ProtocolOptions.new()
      )
    ]
  end

  defp route_config do
    alias Envoy.Api.V2.RouteConfiguration
    alias Envoy.Api.V2.Route.{Route, RouteAction, RouteMatch, VirtualHost}
    RouteConfiguration.new(
      name: "demo",
      virtual_hosts: [
        VirtualHost.new(
          name: "demo",
          domains: ["example.com"],
          routes: [
            Route.new(
              match: RouteMatch.new(path_specifier: {:prefix, "/"}),
              action: {:route, RouteAction.new(cluster_specifier: {:cluster, "demo"})})
          ])
      ])
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
    alias Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager
    import Relay.ProtobufUtil
    Filter.new(
      name: "envoy.http_connection_manager",
      config: mkstruct(HttpConnectionManager.new(
        codec_type: HttpConnectionManager.CodecType.value(:AUTO),
        route_specifier: {:route_config, route_config()},
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
    []
  end

  def endpoints do
    []
  end
end
