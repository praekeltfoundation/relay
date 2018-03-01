defmodule Relay.Server.Macros do
  defmacro discovery_service(
             name,
             xds: xds,
             type_url: type_url,
             service: service,
             resources: resources
           ) do
    stream_func = :"stream_#{resources}" # noqa excoveralls ignores macros
    fetch_func = :"fetch_#{resources}" # noqa

    quote do
      defmodule unquote(name) do
        use GRPC.Server, service: unquote(service)

        alias Relay.{ProtobufUtil, Store}
        alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}

        # TODO: Figure out a way to not have these attributes but also not
        # unquote multiple time?
        @xds unquote(xds)
        @type_url unquote(type_url)

        def xds(), do: @xds
        def type_url(), do: @type_url

        @spec unquote(stream_func)(Enumerable.t, GRPC.Server.Stream.t) :: any
        def unquote(stream_func)(req_stream, stream) do
          IO.inspect({unquote(stream_func), self()})

          :ok = Store.subscribe(Store, @xds, self())
          handle_requests(req_stream, stream)
        end

        @spec unquote(fetch_func)(DiscoveryRequest.t, GRPC.Server.Stream.t) ::
                DiscoveryResponse.t
        def unquote(fetch_func)(_request, _stream) do
          raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
        end

        defp handle_requests(req_stream, stream),
          do: req_stream |> Enum.each(&handle_request(&1, stream))

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
          typed_resources = resources |> Enum.map(&ProtobufUtil.mkany(@type_url, &1))

          DiscoveryResponse.new(
            type_url: @type_url,
            version_info: version_info,
            resources: typed_resources
          )
        end
      end
    end
  end
end

defmodule Relay.Server do
  import Relay.Server.Macros

  discovery_service(
    ListenerDiscoveryService,
    xds: :lds,
    type_url: "type.googleapis.com/envoy.api.v2.Listener",
    service: Envoy.Api.V2.ListenerDiscoveryService.Service,
    resources: :listeners
  )

  discovery_service(
    RouteDiscoveryService,
    xds: :rds,
    type_url: "type.googleapis.com/envoy.api.v2.RouteConfiguration",
    service: Envoy.Api.V2.RouteDiscoveryService.Service,
    resources: :routes
  )

  discovery_service(
    ClusterDiscoveryService,
    xds: :cds,
    type_url: "type.googleapis.com/envoy.api.v2.Cluster",
    service: Envoy.Api.V2.ClusterDiscoveryService.Service,
    resources: :clusters
  )

  discovery_service(
    EndpointDiscoveryService,
    xds: :eds,
    type_url: "type.googleapis.com/envoy.api.v2.ClusterLoadAssignment",
    service: Envoy.Api.V2.EndpointDiscoveryService.Service,
    resources: :endpoints
  )
end
