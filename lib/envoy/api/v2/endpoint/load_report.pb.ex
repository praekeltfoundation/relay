defmodule Envoy.Api.V2.Endpoint.UpstreamLocalityStats do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    locality:                   Envoy.Api.V2.Core.Locality.t,
    total_successful_requests:  non_neg_integer,
    total_requests_in_progress: non_neg_integer,
    total_error_requests:       non_neg_integer,
    load_metric_stats:          [Envoy.Api.V2.Endpoint.EndpointLoadMetricStats.t],
    priority:                   non_neg_integer
  }
  defstruct [:locality, :total_successful_requests, :total_requests_in_progress, :total_error_requests, :load_metric_stats, :priority]

  field :locality, 1, type: Envoy.Api.V2.Core.Locality
  field :total_successful_requests, 2, type: :uint64
  field :total_requests_in_progress, 3, type: :uint64
  field :total_error_requests, 4, type: :uint64
  field :load_metric_stats, 5, repeated: true, type: Envoy.Api.V2.Endpoint.EndpointLoadMetricStats
  field :priority, 6, type: :uint32
end

defmodule Envoy.Api.V2.Endpoint.EndpointLoadMetricStats do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    metric_name:                       String.t,
    num_requests_finished_with_metric: non_neg_integer,
    total_metric_value:                float
  }
  defstruct [:metric_name, :num_requests_finished_with_metric, :total_metric_value]

  field :metric_name, 1, type: :string
  field :num_requests_finished_with_metric, 2, type: :uint64
  field :total_metric_value, 3, type: :double
end

defmodule Envoy.Api.V2.Endpoint.ClusterStats do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    cluster_name:            String.t,
    upstream_locality_stats: [Envoy.Api.V2.Endpoint.UpstreamLocalityStats.t],
    total_dropped_requests:  non_neg_integer
  }
  defstruct [:cluster_name, :upstream_locality_stats, :total_dropped_requests]

  field :cluster_name, 1, type: :string
  field :upstream_locality_stats, 2, repeated: true, type: Envoy.Api.V2.Endpoint.UpstreamLocalityStats
  field :total_dropped_requests, 3, type: :uint64
end
