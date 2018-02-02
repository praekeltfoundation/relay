defmodule Envoy.Api.V2.ClusterLoadAssignment do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    cluster_name: String.t,
    endpoints:    [Envoy.Api.V2.Endpoint.LocalityLbEndpoints.t],
    policy:       Envoy.Api.V2.ClusterLoadAssignment.Policy.t
  }
  defstruct [:cluster_name, :endpoints, :policy]

  field :cluster_name, 1, type: :string
  field :endpoints, 2, repeated: true, type: Envoy.Api.V2.Endpoint.LocalityLbEndpoints
  field :policy, 4, type: Envoy.Api.V2.ClusterLoadAssignment.Policy
end

defmodule Envoy.Api.V2.ClusterLoadAssignment.Policy do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    drop_overload: float
  }
  defstruct [:drop_overload]

  field :drop_overload, 1, type: :double
end

defmodule Envoy.Api.V2.EndpointDiscoveryService.Service do
  use GRPC.Service, name: "envoy.api.v2.EndpointDiscoveryService"

  rpc :StreamEndpoints, stream(Envoy.Api.V2.DiscoveryRequest), stream(Envoy.Api.V2.DiscoveryResponse)
  rpc :FetchEndpoints, Envoy.Api.V2.DiscoveryRequest, Envoy.Api.V2.DiscoveryResponse
end

defmodule Envoy.Api.V2.EndpointDiscoveryService.Stub do
  use GRPC.Stub, service: Envoy.Api.V2.EndpointDiscoveryService.Service
end
