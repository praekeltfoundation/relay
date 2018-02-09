defmodule Relay.Server do
  alias GRPC.Server
  alias Relay.Demo2

  defmodule ListenerDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.ListenerDiscoveryService.Service

    # rpc StreamListeners(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_listeners(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_listeners(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.inspect {:stream_listeners, self()}
        Server.stream_send(stream, Demo2.listeners())
      end)
    end

    # rpc FetchListeners(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_listeners(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_listeners(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule RouteDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.RouteDiscoveryService.Service

    # rpc StreamRoutes(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_routes(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_routes(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.inspect(request)
      end)
    end

    # rpc FetchRoutes(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_routes(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_routes(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule ClusterDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.ClusterDiscoveryService.Service

    # rpc StreamClusters(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_clusters(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_clusters(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.inspect {:stream_clusters, self()}
        Server.stream_send(stream, Demo2.clusters())
      end)
    end

    # rpc FetchClusters(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_clusters(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_clusters(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule EndpointDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.EndpointDiscoveryService.Service

    # rpc StreamEndpoints(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_endpoints(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_endpoints(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.inspect(request)
      end)
    end

    # rpc FetchEndpoints(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_endpoints(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_endpoints(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end
end
