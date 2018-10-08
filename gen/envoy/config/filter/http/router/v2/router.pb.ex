defmodule Envoy.Config.Filter.Http.Router.V2.Router do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          dynamic_stats: Google.Protobuf.BoolValue.t() | nil,
          start_child_span: boolean,
          upstream_log: [Envoy.Config.Filter.Accesslog.V2.AccessLog.t()],
          suppress_envoy_headers: boolean
        }
  defstruct [:dynamic_stats, :start_child_span, :upstream_log, :suppress_envoy_headers]

  field :dynamic_stats, 1, type: Google.Protobuf.BoolValue
  field :start_child_span, 2, type: :bool
  field :upstream_log, 3, repeated: true, type: Envoy.Config.Filter.Accesslog.V2.AccessLog
  field :suppress_envoy_headers, 4, type: :bool
end
