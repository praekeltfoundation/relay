defmodule Relay.Server do
  alias Relay.{Demo2, ProtobufUtil}
  alias Envoy.Api.V2.DiscoveryResponse

  def mkresponse(type_url, resources, opts \\ []) do
    typed_resources = resources |> Enum.map(fn res -> ProtobufUtil.mkany(type_url, res) end)
    DiscoveryResponse.new([type_url: type_url, resources: typed_resources] ++ opts)
  end

  defmodule ListenerDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.ListenerDiscoveryService.Service

    def type_url, do: "type.googleapis.com/envoy.api.v2.Listener"

    # rpc StreamListeners(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_listeners(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_listeners(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.inspect {:stream_listeners, self()}
        GRPC.Server.stream_send(stream, Relay.Server.mkresponse(type_url(), listeners()))
      end)
    end

    defp listeners do
      Demo2.listeners()
    end

    # rpc FetchListeners(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_listeners(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_listeners(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule RouteDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.RouteDiscoveryService.Service

    def type_url, do: "type.googleapis.com/envoy.api.v2.RouteConfiguration"

    # rpc StreamRoutes(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_routes(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_routes(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.inspect {:stream_routes, self()}
        GRPC.Server.stream_send(stream, Relay.Server.mkresponse(type_url(), routes()))
      end)
    end

    defp routes do
      []
    end

    # rpc FetchRoutes(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_routes(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_routes(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule ClusterDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.ClusterDiscoveryService.Service

    def type_url, do: "type.googleapis.com/envoy.api.v2.Cluster"

    # rpc StreamClusters(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_clusters(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_clusters(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.inspect {:stream_clusters, self()}
        GRPC.Server.stream_send(stream, Relay.Server.mkresponse(type_url(), clusters()))
      end)
    end

    defp clusters do
      Demo2.clusters()
    end

    # rpc FetchClusters(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_clusters(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_clusters(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule EndpointDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.EndpointDiscoveryService.Service

    def type_url, do: "type.googleapis.com/envoy.api.v2.ClusterLoadAssignment"

    # rpc StreamEndpoints(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_endpoints(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_endpoints(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.inspect {:stream_endpoints, self()}
        GRPC.Server.stream_send(stream, Relay.Server.mkresponse(type_url(), endpoints()))
      end)
    end

    defp endpoints do
      []
    end

    # rpc FetchEndpoints(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_endpoints(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_endpoints(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end
end
