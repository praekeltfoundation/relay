defmodule Envoy.Config.Filter.Http.HealthCheck.V2.HealthCheck do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          pass_through_mode: Google.Protobuf.BoolValue.t() | nil,
          cache_time: Google.Protobuf.Duration.t() | nil,
          cluster_min_healthy_percentages: %{String.t() => Envoy.Type.Percent.t() | nil},
          headers: [Envoy.Api.V2.Route.HeaderMatcher.t()]
        }
  defstruct [:pass_through_mode, :cache_time, :cluster_min_healthy_percentages, :headers]

  field :pass_through_mode, 1, type: Google.Protobuf.BoolValue
  field :cache_time, 3, type: Google.Protobuf.Duration

  field :cluster_min_healthy_percentages, 4,
    repeated: true,
    type: Envoy.Config.Filter.Http.HealthCheck.V2.HealthCheck.ClusterMinHealthyPercentagesEntry,
    map: true

  field :headers, 5, repeated: true, type: Envoy.Api.V2.Route.HeaderMatcher
end

defmodule Envoy.Config.Filter.Http.HealthCheck.V2.HealthCheck.ClusterMinHealthyPercentagesEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Envoy.Type.Percent.t() | nil
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Envoy.Type.Percent
end
