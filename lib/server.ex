defmodule Relay.Server do
  alias GRPC.Server
  alias Relay.Demo

  defmodule ListenerDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.ListenerDiscoveryService.Service

    # rpc StreamListeners(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_listeners(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_listeners(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.puts("stream_listeners request")
        Server.stream_send(stream, Demo.listeners())
      end)
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
    def stream_routes(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.inspect(request)
      end)
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
    def stream_clusters(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.puts("stream_clusters request")
        Server.stream_send(stream, Demo.clusters())
      end)
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
    def stream_endpoints(req_enum, stream) do
      Enum.each(req_enum, fn(request) ->
        IO.inspect(request)
      end)
    end

    # rpc FetchEndpoints(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_endpoints(Envoy.Api.V2.DiscoveryRequest.t, GRPC.Server.Stream.t) :: Envoy.Api.V2.DiscoveryResponse.t
    def fetch_endpoints(request, _stream) do
      # TODO: Return unimplemented on FetchEndpoints
    end
  end
end
