defmodule Envoy.Api.V2.ClusterLoadAssignment do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          cluster_name: String.t(),
          endpoints: [Envoy.Api.V2.Endpoint.LocalityLbEndpoints.t()],
          policy: Envoy.Api.V2.ClusterLoadAssignment.Policy.t()
        }
  defstruct [:cluster_name, :endpoints, :policy]

  field :cluster_name, 1, type: :string
  field :endpoints, 2, repeated: true, type: Envoy.Api.V2.Endpoint.LocalityLbEndpoints
  field :policy, 4, type: Envoy.Api.V2.ClusterLoadAssignment.Policy
end

defmodule Envoy.Api.V2.ClusterLoadAssignment.Policy do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          drop_overloads: [Envoy.Api.V2.ClusterLoadAssignment.Policy.DropOverload.t()],
          overprovisioning_factor: Google.Protobuf.UInt32Value.t()
        }
  defstruct [:drop_overloads, :overprovisioning_factor]

  field :drop_overloads, 2,
    repeated: true,
    type: Envoy.Api.V2.ClusterLoadAssignment.Policy.DropOverload

  field :overprovisioning_factor, 3, type: Google.Protobuf.UInt32Value
end

defmodule Envoy.Api.V2.ClusterLoadAssignment.Policy.DropOverload do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          category: String.t(),
          drop_percentage: Envoy.Type.FractionalPercent.t()
        }
  defstruct [:category, :drop_percentage]

  field :category, 1, type: :string
  field :drop_percentage, 2, type: Envoy.Type.FractionalPercent
end

defmodule Envoy.Api.V2.EndpointDiscoveryService.Service do
  @moduledoc false
  use GRPC.Service, name: "envoy.api.v2.EndpointDiscoveryService"

  rpc :StreamEndpoints,
      stream(Envoy.Api.V2.DiscoveryRequest),
      stream(Envoy.Api.V2.DiscoveryResponse)

  rpc :FetchEndpoints, Envoy.Api.V2.DiscoveryRequest, Envoy.Api.V2.DiscoveryResponse
end

defmodule Envoy.Api.V2.EndpointDiscoveryService.Stub do
  @moduledoc false
  use GRPC.Stub, service: Envoy.Api.V2.EndpointDiscoveryService.Service
end
