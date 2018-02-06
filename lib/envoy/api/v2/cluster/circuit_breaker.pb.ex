defmodule Envoy.Api.V2.Cluster.CircuitBreakers do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    thresholds: [Envoy.Api.V2.Cluster.CircuitBreakers.Thresholds.t]
  }
  defstruct [:thresholds]

  field :thresholds, 1, repeated: true, type: Envoy.Api.V2.Cluster.CircuitBreakers.Thresholds
end

defmodule Envoy.Api.V2.Cluster.CircuitBreakers.Thresholds do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    priority:             integer,
    max_connections:      Google.Protobuf.UInt32Value.t,
    max_pending_requests: Google.Protobuf.UInt32Value.t,
    max_requests:         Google.Protobuf.UInt32Value.t,
    max_retries:          Google.Protobuf.UInt32Value.t
  }
  defstruct [:priority, :max_connections, :max_pending_requests, :max_requests, :max_retries]

  field :priority, 1, type: Envoy.Api.V2.Core.RoutingPriority, enum: true
  field :max_connections, 2, type: Google.Protobuf.UInt32Value
  field :max_pending_requests, 3, type: Google.Protobuf.UInt32Value
  field :max_requests, 4, type: Google.Protobuf.UInt32Value
  field :max_retries, 5, type: Google.Protobuf.UInt32Value
end
