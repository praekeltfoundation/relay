defmodule Envoy.Api.V2.Filter.Http.Router do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    dynamic_stats:    Google.Protobuf.BoolValue.t,
    start_child_span: boolean,
    upstream_log:     [Envoy.Api.V2.Filter.Accesslog.AccessLog.t]
  }
  defstruct [:dynamic_stats, :start_child_span, :upstream_log]

  field :dynamic_stats, 1, type: Google.Protobuf.BoolValue
  field :start_child_span, 2, type: :bool
  field :upstream_log, 3, repeated: true, type: Envoy.Api.V2.Filter.Accesslog.AccessLog
end
