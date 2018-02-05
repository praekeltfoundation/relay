defmodule Envoy.Api.V2.Endpoint.Endpoint do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    address: Envoy.Api.V2.Address.t
  }
  defstruct [:address]

  field :address, 1, type: Envoy.Api.V2.Address
end

defmodule Envoy.Api.V2.Endpoint.LbEndpoint do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    endpoint:              Envoy.Api.V2.Endpoint.Endpoint.t,
    health_status:         integer,
    metadata:              Envoy.Api.V2.Metadata.t,
    load_balancing_weight: Google.Protobuf.UInt32Value.t
  }
  defstruct [:endpoint, :health_status, :metadata, :load_balancing_weight]

  field :endpoint, 1, type: Envoy.Api.V2.Endpoint.Endpoint
  field :health_status, 2, type: Envoy.Api.V2.HealthStatus, enum: true
  field :metadata, 3, type: Envoy.Api.V2.Metadata
  field :load_balancing_weight, 4, type: Google.Protobuf.UInt32Value
end

defmodule Envoy.Api.V2.Endpoint.LocalityLbEndpoints do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    locality:              Envoy.Api.V2.Locality.t,
    lb_endpoints:          [Envoy.Api.V2.Endpoint.LbEndpoint.t],
    load_balancing_weight: Google.Protobuf.UInt32Value.t,
    priority:              non_neg_integer
  }
  defstruct [:locality, :lb_endpoints, :load_balancing_weight, :priority]

  field :locality, 1, type: Envoy.Api.V2.Locality
  field :lb_endpoints, 2, repeated: true, type: Envoy.Api.V2.Endpoint.LbEndpoint
  field :load_balancing_weight, 3, type: Google.Protobuf.UInt32Value
  field :priority, 5, type: :uint32
end
