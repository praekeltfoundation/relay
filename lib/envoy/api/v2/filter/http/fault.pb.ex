defmodule Envoy.Api.V2.Filter.Http.FaultAbort do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    error_type:  {atom, any},
    percent:     non_neg_integer
  }
  defstruct [:error_type, :percent]

  oneof :error_type, 0
  field :percent, 1, type: :uint32
  field :http_status, 2, type: :uint32, oneof: 0
end

defmodule Envoy.Api.V2.Filter.Http.HTTPFault do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    delay:            Envoy.Api.V2.Filter.FaultDelay.t,
    abort:            Envoy.Api.V2.Filter.Http.FaultAbort.t,
    upstream_cluster: String.t,
    headers:          [Envoy.Api.V2.Route.HeaderMatcher.t],
    downstream_nodes: [String.t]
  }
  defstruct [:delay, :abort, :upstream_cluster, :headers, :downstream_nodes]

  field :delay, 1, type: Envoy.Api.V2.Filter.FaultDelay
  field :abort, 2, type: Envoy.Api.V2.Filter.Http.FaultAbort
  field :upstream_cluster, 3, type: :string
  field :headers, 4, repeated: true, type: Envoy.Api.V2.Route.HeaderMatcher
  field :downstream_nodes, 5, repeated: true, type: :string
end
