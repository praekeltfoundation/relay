defmodule Relay.Server do
  defmodule EndpointDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.EndpointDiscoveryService.Service
  end

  defmodule ListenerDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.ListenerDiscoveryService.Service

    # rpc StreamListeners(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_listeners(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_listeners(request, stream) do
      # TODO
    end

    # rpc FetchListeners(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_listeners(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_listeners(request, _stream) do
      # TODO: Return unimplemented on FetchListeners
    end
  end

  defmodule RouteDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.RouteDiscoveryService.Service

    # rpc StreamRoutes(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_routes(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_routes(request, stream) do
      # TODO
    end

    # rpc FetchRoutes(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_routes(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_routes(request, _stream) do
      # TODO: Return unimplemented on FetchRoutes
    end
  end

  defmodule ClusterDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.ClusterDiscoveryService.Service

    # rpc StreamClusters(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_clusters(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_clusters(request, stream) do
      # TODO
    end

    # rpc FetchClusters(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_clusters(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_clusters(request, _stream) do
      # TODO: Return unimplemented on FetchClusters
    end
  end

  defmodule EndpointDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.EndpointDiscoveryService.Service

    # rpc StreamEndpoints(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_endpoints(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_endpoints(request, stream) do
      # TODO
    end

    # rpc FetchEndpoints(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_endpoints(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_endpoints(request, _stream) do
      # TODO: Return unimplemented on FetchEndpoints
    end
  end
end
