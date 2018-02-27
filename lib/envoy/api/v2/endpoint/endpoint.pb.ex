defmodule Envoy.Api.V2.Endpoint.Endpoint do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          address: Envoy.Api.V2.Core.Address.t()
        }
  defstruct [:address]

  field :address, 1, type: Envoy.Api.V2.Core.Address
end

defmodule Envoy.Api.V2.Endpoint.LbEndpoint do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          endpoint: Envoy.Api.V2.Endpoint.Endpoint.t(),
          health_status: integer,
          metadata: Envoy.Api.V2.Core.Metadata.t(),
          load_balancing_weight: Google.Protobuf.UInt32Value.t()
        }
  defstruct [:endpoint, :health_status, :metadata, :load_balancing_weight]

  field :endpoint, 1, type: Envoy.Api.V2.Endpoint.Endpoint
  field :health_status, 2, type: Envoy.Api.V2.Core.HealthStatus, enum: true
  field :metadata, 3, type: Envoy.Api.V2.Core.Metadata
  field :load_balancing_weight, 4, type: Google.Protobuf.UInt32Value
end

defmodule Envoy.Api.V2.Endpoint.LocalityLbEndpoints do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          locality: Envoy.Api.V2.Core.Locality.t(),
          lb_endpoints: [Envoy.Api.V2.Endpoint.LbEndpoint.t()],
          load_balancing_weight: Google.Protobuf.UInt32Value.t(),
          priority: non_neg_integer
        }
  defstruct [:locality, :lb_endpoints, :load_balancing_weight, :priority]

  field :locality, 1, type: Envoy.Api.V2.Core.Locality
  field :lb_endpoints, 2, repeated: true, type: Envoy.Api.V2.Endpoint.LbEndpoint
  field :load_balancing_weight, 3, type: Google.Protobuf.UInt32Value
  field :priority, 5, type: :uint32
end
