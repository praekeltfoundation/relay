defmodule Relay.Demo do
  alias Relay.Store

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  defp call_async(func_name) do
    Task.async(fn ->
      :ok = GenServer.call(__MODULE__, func_name)
    end)
  end

  # Callbacks

  def init(_args) do
    call_async(:clusters)
    call_async(:listeners)
    call_async(:routes)
    call_async(:endpoints)
    {:ok, %{}}
  end

  def handle_call(:clusters, _from, state) do
    Store.update(Store, :cds, "1", clusters())
    {:reply, :ok, state}
  end

  def handle_call(:listeners, _from, state) do
    Store.update(Store, :lds, "1", listeners())
    {:reply, :ok, state}
  end

  def handle_call(:routes, _from, state) do
    Store.update(Store, :rds, "1", routes())
    {:reply, :ok, state}
  end

  def handle_call(:endpoints, _from, state) do
    Store.update(Store, :eds, "1", endpoints())
    {:reply, :ok, state}
  end

  # Internals

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
