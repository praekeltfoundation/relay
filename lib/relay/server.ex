defmodule Relay.Server do
  alias Relay.{ProtobufUtil, Store}
  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}

  defp mkresponse(type_url, version_info, resources) do
    typed_resources = resources |> Enum.map(fn res -> ProtobufUtil.mkany(type_url, res) end)
    DiscoveryResponse.new(
      type_url: type_url, version_info: version_info, resources: typed_resources)
  end

  defp stream_send_response(stream, type_url, version_info, resources) do
    GRPC.Server.stream_send(stream, mkresponse(type_url, version_info, resources))
  end

  def stream_updates(req_stream, stream, xds, type_url) do
    # TODO: Have Store send us the initial state as an update
    {:ok, version_info, resources} = Store.subscribe(Store, xds, self())
    send(self(), {xds, version_info, resources})
    handle_requests(req_stream, stream, xds, type_url)
  end

  def handle_requests(req_stream, stream, xds, type_url) do
    #...subsequent responses sent when we receive changes
    req_stream |> Enum.each(&handle_request(&1, stream, xds, type_url))
  end

  def handle_request(_request, stream, xds, type_url) do
    # TODO: How to handle errors?
    # FIXME: What if we get multiple updates between requests?
    receive do
      {^xds, version_info, resources} ->
        stream_send_response(stream, type_url, version_info, resources)
    end
  end

  defmodule ListenerDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.ListenerDiscoveryService.Service

    def xds, do: :lds
    def type_url, do: "type.googleapis.com/envoy.api.v2.Listener"

    # rpc StreamListeners(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_listeners(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_listeners(req_stream, stream) do
      IO.inspect {:stream_listeners, self()}
      Relay.Server.stream_updates(req_stream, stream, xds(), type_url())
    end

    # rpc FetchListeners(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_listeners(DiscoveryRequest.t, GRPC.Server.Stream.t) :: DiscoveryResponse.t
    def fetch_listeners(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule RouteDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.RouteDiscoveryService.Service

    def xds, do: :rds
    def type_url, do: "type.googleapis.com/envoy.api.v2.RouteConfiguration"

    # rpc StreamRoutes(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_routes(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_routes(req_stream, stream) do
      IO.inspect {:stream_routes, self()}
      Relay.Server.stream_updates(req_stream, stream, xds(), type_url())
    end

    # rpc FetchRoutes(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_routes(DiscoveryRequest.t, GRPC.Server.Stream.t) :: DiscoveryResponse.t
    def fetch_routes(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule ClusterDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.ClusterDiscoveryService.Service

    def xds, do: :cds
    def type_url, do: "type.googleapis.com/envoy.api.v2.Cluster"

    # rpc StreamClusters(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_clusters(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_clusters(req_stream, stream) do
      IO.inspect {:stream_clusters, self()}
      Relay.Server.stream_updates(req_stream, stream, xds(), type_url())
    end

    # rpc FetchClusters(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_clusters(DiscoveryRequest.t, GRPC.Server.Stream.t) :: DiscoveryResponse.t
    def fetch_clusters(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule EndpointDiscoveryService do
    use GRPC.Server, service: Envoy.Api.V2.EndpointDiscoveryService.Service

    def xds, do: :eds
    def type_url, do: "type.googleapis.com/envoy.api.v2.ClusterLoadAssignment"

    # rpc StreamEndpoints(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_endpoints(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_endpoints(req_stream, stream) do
      IO.inspect {:stream_endpoints, self()}
      Relay.Server.stream_updates(req_stream, stream, xds(), type_url())
    end

    # rpc FetchEndpoints(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_endpoints(DiscoveryRequest.t, GRPC.Server.Stream.t) :: DiscoveryResponse.t
    def fetch_endpoints(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end
end
