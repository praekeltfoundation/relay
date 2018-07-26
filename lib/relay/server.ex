defmodule Relay.Server.Macros do
  @moduledoc false

  alias Envoy.Api.V2.DiscoveryRequest

  # This function is a hack to work around coverage issues. Any line matching
  # ~r/process_macro_opts\(/ is ignored by the coverage tool.
  def process_macro_opts(opts) do
    {resources, opts} = Keyword.pop(opts, :resources)

    opts
    |> Keyword.put(:stream_func, :"stream_#{resources}")
    |> Keyword.put(:fetch_func, :"fetch_#{resources}")
    |> Keyword.put_new(:name_field, :name)
    |> Map.new()
  end

  def filter_resources(%DiscoveryRequest{resource_names: []}, resources, _field), do: resources

  def filter_resources(request, resources, field) do
    resources |> Enum.filter(&(Map.fetch!(&1, field) in request.resource_names))
  end

  defmacro discovery_service(name, opts) do
    %{
      xds: xds,
      type_url: type_url,
      service: service,
      resource_type: resource_type,
      stream_func: stream_func,
      fetch_func: fetch_func,
      name_field: name_field
    } = process_macro_opts(opts)

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
        def unquote(stream_func)(req_enum, stream) do
          Log.debug("Stream started: #{inspect(self())} #{Log.mfa()}")
          :ok = Publisher.subscribe(Publisher, @xds, self())
          handle_requests(req_enum, stream)
        end

        @spec unquote(fetch_func)(DiscoveryRequest.t(), Stream.t()) :: DiscoveryResponse.t()
        def unquote(fetch_func)(_request, _stream) do
          raise GRPC.RPCError, status: GRPC.Status.unimplemented(), message: "not implemented"
        end

        @spec handle_requests(Enumerable.t(), Stream.t()) :: :ok
        defp handle_requests(req_enum, stream) do
          req_enum |> Enum.each(&handle_request(&1, stream))
        end

        @spec handle_request(DiscoveryRequest.t(), Stream.t()) :: Stream.t()
        defp handle_request(request, stream) do
          # TODO: How to handle errors?
          # FIXME: What if we get multiple updates between requests?
          receive do
            {@xds, version_info, resources} ->
              filtered_resources = filter_resources(request, resources, unquote(name_field))
              send_reply(stream, version_info, filtered_resources)
          end
        end

        @spec send_reply(Stream.t(), String.t(), [unquote(resource_type).t]) :: Stream.t()
        defp send_reply(stream, version_info, resources),
          do: GRPC.Server.send_reply(stream, mkresponse(version_info, resources))

        @spec mkresponse(String.t(), [unquote(resource_type).t]) :: DiscoveryResponse.t()
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
    resource_type: Envoy.Api.V2.ClusterLoadAssignment,
    name_field: :cluster_name
  )
end
