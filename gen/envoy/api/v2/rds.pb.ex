defmodule Envoy.Api.V2.RouteConfiguration do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          virtual_hosts: [Envoy.Api.V2.Route.VirtualHost.t()],
          internal_only_headers: [String.t()],
          response_headers_to_add: [Envoy.Api.V2.Core.HeaderValueOption.t()],
          response_headers_to_remove: [String.t()],
          request_headers_to_add: [Envoy.Api.V2.Core.HeaderValueOption.t()],
          request_headers_to_remove: [String.t()],
          validate_clusters: Google.Protobuf.BoolValue.t() | nil
        }
  defstruct [
    :name,
    :virtual_hosts,
    :internal_only_headers,
    :response_headers_to_add,
    :response_headers_to_remove,
    :request_headers_to_add,
    :request_headers_to_remove,
    :validate_clusters
  ]

  field :name, 1, type: :string
  field :virtual_hosts, 2, repeated: true, type: Envoy.Api.V2.Route.VirtualHost
  field :internal_only_headers, 3, repeated: true, type: :string
  field :response_headers_to_add, 4, repeated: true, type: Envoy.Api.V2.Core.HeaderValueOption
  field :response_headers_to_remove, 5, repeated: true, type: :string
  field :request_headers_to_add, 6, repeated: true, type: Envoy.Api.V2.Core.HeaderValueOption
  field :request_headers_to_remove, 8, repeated: true, type: :string
  field :validate_clusters, 7, type: Google.Protobuf.BoolValue
end

defmodule Envoy.Api.V2.RouteDiscoveryService.Service do
  @moduledoc false
  use GRPC.Service, name: "envoy.api.v2.RouteDiscoveryService"

  rpc :StreamRoutes, stream(Envoy.Api.V2.DiscoveryRequest), stream(Envoy.Api.V2.DiscoveryResponse)

  rpc :IncrementalRoutes,
      stream(Envoy.Api.V2.IncrementalDiscoveryRequest),
      stream(Envoy.Api.V2.IncrementalDiscoveryResponse)

  rpc :FetchRoutes, Envoy.Api.V2.DiscoveryRequest, Envoy.Api.V2.DiscoveryResponse
end

defmodule Envoy.Api.V2.RouteDiscoveryService.Stub do
  @moduledoc false
  use GRPC.Stub, service: Envoy.Api.V2.RouteDiscoveryService.Service
end
