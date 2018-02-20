defmodule Relay.Server do
  alias Relay.{ProtobufUtil, Store}
  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}

  defmodule Impl do
    defmacro __using__(xds: xds, type_url: type_url, service: service) do
      quote do
        use GRPC.Server, service: unquote(service)

        # TODO: Figure out a way to not have these attributes but also not
        # unquote multiple time?
        @xds unquote(xds)
        @type_url unquote(type_url)

        def xds(), do: @xds
        def type_url(), do: @type_url

        defp stream_updates(req_stream, stream) do
          # TODO: Have Store send us the initial state as an update
          {:ok, version_info, resources} = Store.subscribe(Store, @xds, self())
          send(self(), {@xds, version_info, resources})
          handle_requests(req_stream, stream)
        end

        defp handle_requests(req_stream, stream) do
          #...subsequent responses sent when we receive changes
          req_stream |> Enum.each(&handle_request(&1, stream))
        end

        defp handle_request(_request, stream) do
          # TODO: How to handle errors?
          # FIXME: What if we get multiple updates between requests?
          receive do
            {@xds, version_info, resources} ->
              stream_send_response(stream, version_info, resources)
          end
        end

        defp stream_send_response(stream, version_info, resources) do
          GRPC.Server.stream_send(stream, mkresponse(version_info, resources))
        end

        defp mkresponse(version_info, resources) do
          typed_resources = resources |> Enum.map(fn res -> ProtobufUtil.mkany(@type_url, res) end)
          DiscoveryResponse.new(
            type_url: @type_url, version_info: version_info, resources: typed_resources)
        end
      end
    end
  end

  defmodule ListenerDiscoveryService do
    use Relay.Server.Impl,
      xds: :lds,
      type_url: "type.googleapis.com/envoy.api.v2.Listener",
      service: Envoy.Api.V2.ListenerDiscoveryService.Service

    # rpc StreamListeners(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_listeners(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_listeners(req_stream, stream) do
      IO.inspect {:stream_listeners, self()}
      stream_updates(req_stream, stream)
    end

    # rpc FetchListeners(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_listeners(DiscoveryRequest.t, GRPC.Server.Stream.t) :: DiscoveryResponse.t
    def fetch_listeners(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule RouteDiscoveryService do
    use Relay.Server.Impl,
      xds: :rds,
      type_url: "type.googleapis.com/envoy.api.v2.RouteConfiguration",
      service: Envoy.Api.V2.RouteDiscoveryService.Service

    # rpc StreamRoutes(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_routes(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_routes(req_stream, stream) do
      IO.inspect {:stream_routes, self()}
      stream_updates(req_stream, stream)
    end

    # rpc FetchRoutes(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_routes(DiscoveryRequest.t, GRPC.Server.Stream.t) :: DiscoveryResponse.t
    def fetch_routes(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule ClusterDiscoveryService do
    use Relay.Server.Impl,
      xds: :cds,
      type_url: "type.googleapis.com/envoy.api.v2.Cluster",
      service: Envoy.Api.V2.ClusterDiscoveryService.Service

    # rpc StreamClusters(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_clusters(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_clusters(req_stream, stream) do
      IO.inspect {:stream_clusters, self()}
      stream_updates(req_stream, stream)
    end

    # rpc FetchClusters(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_clusters(DiscoveryRequest.t, GRPC.Server.Stream.t) :: DiscoveryResponse.t
    def fetch_clusters(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end

  defmodule EndpointDiscoveryService do
    use Relay.Server.Impl,
      xds: :eds,
      type_url: "type.googleapis.com/envoy.api.v2.ClusterLoadAssignment",
      service: Envoy.Api.V2.EndpointDiscoveryService.Service

    # rpc StreamEndpoints(stream DiscoveryRequest) returns (stream DiscoveryResponse)
    @spec stream_endpoints(Enumerable.t, GRPC.Server.Stream.t) :: any
    def stream_endpoints(req_stream, stream) do
      IO.inspect {:stream_endpoints, self()}
      stream_updates(req_stream, stream)
    end

    # rpc FetchEndpoints(DiscoveryRequest) returns (DiscoveryResponse)
    @spec fetch_endpoints(DiscoveryRequest.t, GRPC.Server.Stream.t) :: DiscoveryResponse.t
    def fetch_endpoints(_request, _stream) do
      raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
    end
  end
end
