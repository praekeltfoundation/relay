defmodule Relay.Demo.Certs do
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
    Store.update(Store, :lds, v, listeners())
    %{state | version: state.version + 1}
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

  defp socket_address(address, port) do
    alias Envoy.Api.V2.Core.{Address, SocketAddress}
    sock = SocketAddress.new(address: address, port_specifier: {:port_value, port})
    Address.new(address: {:socket_address, sock})
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
end
