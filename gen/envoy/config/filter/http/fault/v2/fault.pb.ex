defmodule Envoy.Config.Filter.Http.Fault.V2.FaultAbort do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          error_type: {atom, any},
          percent: non_neg_integer,
          percentage: Envoy.Type.FractionalPercent.t() | nil
        }
  defstruct [:error_type, :percent, :percentage]

  oneof :error_type, 0
  field :percent, 1, type: :uint32, deprecated: true
  field :http_status, 2, type: :uint32, oneof: 0
  field :percentage, 3, type: Envoy.Type.FractionalPercent
end

defmodule Envoy.Config.Filter.Http.Fault.V2.HTTPFault do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          delay: Envoy.Config.Filter.Fault.V2.FaultDelay.t() | nil,
          abort: Envoy.Config.Filter.Http.Fault.V2.FaultAbort.t() | nil,
          upstream_cluster: String.t(),
          headers: [Envoy.Api.V2.Route.HeaderMatcher.t()],
          downstream_nodes: [String.t()]
        }
  defstruct [:delay, :abort, :upstream_cluster, :headers, :downstream_nodes]

  field :delay, 1, type: Envoy.Config.Filter.Fault.V2.FaultDelay
  field :abort, 2, type: Envoy.Config.Filter.Http.Fault.V2.FaultAbort
  field :upstream_cluster, 3, type: :string
  field :headers, 4, repeated: true, type: Envoy.Api.V2.Route.HeaderMatcher
  field :downstream_nodes, 5, repeated: true, type: :string
end
