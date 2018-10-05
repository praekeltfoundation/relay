defmodule Envoy.Api.V2.Endpoint.UpstreamLocalityStats do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          locality: Envoy.Api.V2.Core.Locality.t(),
          total_successful_requests: non_neg_integer,
          total_requests_in_progress: non_neg_integer,
          total_error_requests: non_neg_integer,
          load_metric_stats: [Envoy.Api.V2.Endpoint.EndpointLoadMetricStats.t()],
          upstream_endpoint_stats: [Envoy.Api.V2.Endpoint.UpstreamEndpointStats.t()],
          priority: non_neg_integer
        }
  defstruct [
    :locality,
    :total_successful_requests,
    :total_requests_in_progress,
    :total_error_requests,
    :load_metric_stats,
    :upstream_endpoint_stats,
    :priority
  ]

  field :locality, 1, type: Envoy.Api.V2.Core.Locality
  field :total_successful_requests, 2, type: :uint64
  field :total_requests_in_progress, 3, type: :uint64
  field :total_error_requests, 4, type: :uint64
  field :load_metric_stats, 5, repeated: true, type: Envoy.Api.V2.Endpoint.EndpointLoadMetricStats

  field :upstream_endpoint_stats, 7,
    repeated: true,
    type: Envoy.Api.V2.Endpoint.UpstreamEndpointStats

  field :priority, 6, type: :uint32
end

defmodule Envoy.Api.V2.Endpoint.UpstreamEndpointStats do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          address: Envoy.Api.V2.Core.Address.t(),
          total_successful_requests: non_neg_integer,
          total_requests_in_progress: non_neg_integer,
          total_error_requests: non_neg_integer,
          load_metric_stats: [Envoy.Api.V2.Endpoint.EndpointLoadMetricStats.t()]
        }
  defstruct [
    :address,
    :total_successful_requests,
    :total_requests_in_progress,
    :total_error_requests,
    :load_metric_stats
  ]

  field :address, 1, type: Envoy.Api.V2.Core.Address
  field :total_successful_requests, 2, type: :uint64
  field :total_requests_in_progress, 3, type: :uint64
  field :total_error_requests, 4, type: :uint64
  field :load_metric_stats, 5, repeated: true, type: Envoy.Api.V2.Endpoint.EndpointLoadMetricStats
end

defmodule Envoy.Api.V2.Endpoint.EndpointLoadMetricStats do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          metric_name: String.t(),
          num_requests_finished_with_metric: non_neg_integer,
          total_metric_value: float
        }
  defstruct [:metric_name, :num_requests_finished_with_metric, :total_metric_value]

  field :metric_name, 1, type: :string
  field :num_requests_finished_with_metric, 2, type: :uint64
  field :total_metric_value, 3, type: :double
end

defmodule Envoy.Api.V2.Endpoint.ClusterStats do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          cluster_name: String.t(),
          upstream_locality_stats: [Envoy.Api.V2.Endpoint.UpstreamLocalityStats.t()],
          total_dropped_requests: non_neg_integer,
          dropped_requests: [Envoy.Api.V2.Endpoint.ClusterStats.DroppedRequests.t()],
          load_report_interval: Google.Protobuf.Duration.t()
        }
  defstruct [
    :cluster_name,
    :upstream_locality_stats,
    :total_dropped_requests,
    :dropped_requests,
    :load_report_interval
  ]

  field :cluster_name, 1, type: :string

  field :upstream_locality_stats, 2,
    repeated: true,
    type: Envoy.Api.V2.Endpoint.UpstreamLocalityStats

  field :total_dropped_requests, 3, type: :uint64

  field :dropped_requests, 5,
    repeated: true,
    type: Envoy.Api.V2.Endpoint.ClusterStats.DroppedRequests

  field :load_report_interval, 4, type: Google.Protobuf.Duration
end

defmodule Envoy.Api.V2.Endpoint.ClusterStats.DroppedRequests do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          category: String.t(),
          dropped_count: non_neg_integer
        }
  defstruct [:category, :dropped_count]

  field :category, 1, type: :string
  field :dropped_count, 2, type: :uint64
end
