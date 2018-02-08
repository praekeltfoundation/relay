defmodule Relay.Demo do
  alias Envoy.Api.V2.DiscoveryResponse
  alias Envoy.Api.V2.Core.{Http1ProtocolOptions}
  alias Google.Protobuf.{Any, Duration}

  @cds_type "type.googleapis.com/envoy.api.v2.Cluster"
  @lds_type "type.googleapis.com/envoy.api.v2.Listener"

  defp typed_resource(type, res) do
    value = GRPC.Message.Protobuf.encode(Any, res)
    Any.new(type_url: type, value: value)
  end

  defp typed_resources(type, resources) do
    resources |> Enum.map(&typed_resource(type, &1))
  end

  defp socket_address(address, port) do
    alias Envoy.Api.V2.Core.{Address, SocketAddress}
    sock = SocketAddress.new(address: address, port_specifier: {:port_value, port})
    Address.new(address: {:socket_address, sock})
  end

  def clusters do
    alias Envoy.Api.V2.Cluster

    resources = [
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
    DiscoveryResponse.new(
      version_info: "1",
      resources: typed_resources(@cds_type, resources),
      type_url: @cds_type
    )
  end

#  defp default_http_conn_manager_filter(name) do
#    alias Envoy.Api.V2.Listener.Filter
#    alias Envoy.Config.Filter.Network.HttpConnectionManager.V2.{HttpConnectionManager, HttpFilter}
#    alias Google.Protobuf.Struct
#    Filter.new(
#      name: "envoy.http_connection_manager",
#      config: Struct.new(fields: %{
#        "codec_type" => HttpConnectionManager.CodecType.:AUTO,
#        "stat_prefix" => name,
#        "http_filters" => [
#          HttpFilter.new(
#            name: "envoy.router",
#            config: Struct.new(fields: %{
#
#            })
#          )
#        ]
#      })
#    )
#  end

  def listeners do
    alias Envoy.Api.V2.Listener

    resources = [
      Listener.new(
        name: "http",
        address: socket_address("0.0.0.0", 8080),
        filter_chains: [
          Listener.FilterChain.new(
            filter_chain_match: Listener.FilterChainMatch.new(),
            filters: []
          ),
        ]
      )
    ]

    DiscoveryResponse.new(
      version_info: "1",
      resources: typed_resources(@lds_type, resources),
      type_url: @lds_type
    )
  end
end
