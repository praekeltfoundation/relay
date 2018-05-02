defmodule Relay.Server.Macros do
  @moduledoc false

  # This function is a hack to work around coverage issues. Any line matching
  # ~r/mk_server_func\(/ is ignored by the coverage tool.
  defp mk_server_func(prefix, resources), do: :"#{prefix}_#{resources}"

  defmacro discovery_service(
             name,
             xds: xds,
             type_url: type_url,
             service: service,
             resources: resources,
             resource_type: resource_type
           ) do
    stream_func = mk_server_func("stream", resources)
    fetch_func = mk_server_func("fetch", resources)

    quote do
      defmodule unquote(name) do
        use GRPC.Server, service: unquote(service)

        require LogWrapper
        alias LogWrapper, as: Log

        alias Relay.{ProtobufUtil, Publisher}
        alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}
        alias GRPC.Server.Stream

        # TODO: Figure out a way to not have these attributes but also not
        # unquote multiple time?
        @xds unquote(xds)
        @type_url unquote(type_url)

        def xds, do: @xds
        def type_url, do: @type_url

        @spec unquote(stream_func)(Enumerable.t(), Stream.t()) :: Stream.t()
        def unquote(stream_func)(req_enum, stream0) do
          log_debug("Stream started")
          :ok = Publisher.subscribe(Publisher, @xds, self())
          handle_requests(req_enum, stream0)
        end

        @spec unquote(fetch_func)(DiscoveryRequest.t(), Stream.t()) :: DiscoveryResponse.t()
        def unquote(fetch_func)(_request, _stream) do
          raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
        end

        @spec handle_requests(Enumerable.t(), Stream.t()) :: Stream.t()
        defp handle_requests(req_enum, stream0) do
          # We must use the `Stream` returned by `GRPC.Server.send_reply` for
          # each subsequent request and return the final `Stream`.
          req_enum |> Enum.reduce(stream0, &handle_request(&1, &2))
        end

        @spec handle_request(DiscoveryRequest.t(), Stream.t()) :: Stream.t()
        defp handle_request(request, stream) do
          log_debug(fn ->
            case request.resource_names do
              [] ->
                "Received discovery request from node #{request.node.id}"

              names ->
                "Received discovery request from node #{request.node.id}: #{
                  Enum.join(names, ", ")
                }"
            end
          end)

          # TODO: How to handle errors?
          # FIXME: What if we get multiple updates between requests?
          receive do
            {@xds, version_info, resources} ->
              send_reply(stream, version_info, resources)
          end
        end

        @spec send_reply(Stream.t(), String.t(), [unquote(resource_type).t]) :: Stream.t()
        defp send_reply(stream, version_info, resources) do
          log_debug("Sending discovery response")
          GRPC.Server.send_reply(stream, mkresponse(version_info, resources))
        end

        @spec mkresponse(String.t(), [unquote(resource_type).t]) :: DiscoveryResponse.t()
        defp mkresponse(version_info, resources) do
          typed_resources = resources |> Enum.map(&ProtobufUtil.mkany(@type_url, &1))

          DiscoveryResponse.new(
            type_url: @type_url,
            version_info: version_info,
            resources: typed_resources
          )
        end

        defp log_debug(fun) when is_function(fun, 0),
          do: Log.debug(fn -> "#{unquote(stream_func)} #{inspect(self())}: #{fun.()}" end)

        defp log_debug(str) when is_binary(str),
          do: Log.debug(fn -> "#{unquote(stream_func)} #{inspect(self())}: #{str}" end)
      end
    end
  end
end

defmodule Relay.Server do
  @moduledoc """
  GRPC API for Envoy to use for service discovery.
  """

  import Relay.Server.Macros

  discovery_service(
    ListenerDiscoveryService,
    xds: :lds,
    type_url: "type.googleapis.com/envoy.api.v2.Listener",
    service: Envoy.Api.V2.ListenerDiscoveryService.Service,
    resources: :listeners,
    resource_type: Envoy.Api.V2.Listener
  )

  discovery_service(
    RouteDiscoveryService,
    xds: :rds,
    type_url: "type.googleapis.com/envoy.api.v2.RouteConfiguration",
    service: Envoy.Api.V2.RouteDiscoveryService.Service,
    resources: :routes,
    resource_type: Envoy.Api.V2.RouteConfiguration
  )

  discovery_service(
    ClusterDiscoveryService,
    xds: :cds,
    type_url: "type.googleapis.com/envoy.api.v2.Cluster",
    service: Envoy.Api.V2.ClusterDiscoveryService.Service,
    resources: :clusters,
    resource_type: Envoy.Api.V2.Cluster
  )

  discovery_service(
    EndpointDiscoveryService,
    xds: :eds,
    type_url: "type.googleapis.com/envoy.api.v2.ClusterLoadAssignment",
    service: Envoy.Api.V2.EndpointDiscoveryService.Service,
    resources: :endpoints,
    resource_type: Envoy.Api.V2.ClusterLoadAssignment
  )
end
