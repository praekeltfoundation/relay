defmodule Envoy.Api.V2.Filter.Http.HealthCheck do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    pass_through_mode:               Google.Protobuf.BoolValue.t,
    endpoint:                        String.t,
    cache_time:                      Google.Protobuf.Duration.t,
    cluster_min_healthy_percentages: %{String.t => Envoy.Api.V2.Percent.t}
  }
  defstruct [:pass_through_mode, :endpoint, :cache_time, :cluster_min_healthy_percentages]

  field :pass_through_mode, 1, type: Google.Protobuf.BoolValue
  field :endpoint, 2, type: :string
  field :cache_time, 3, type: Google.Protobuf.Duration
  field :cluster_min_healthy_percentages, 4, repeated: true, type: Envoy.Api.V2.Filter.Http.HealthCheck.ClusterMinHealthyPercentagesEntry, map: true
end

defmodule Envoy.Api.V2.Filter.Http.HealthCheck.ClusterMinHealthyPercentagesEntry do
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
    key:   String.t,
    value: Envoy.Api.V2.Percent.t
  }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Envoy.Api.V2.Percent
end
