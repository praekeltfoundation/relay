defmodule Envoy.Api.V2.Cluster.OutlierDetection do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          consecutive_5xx: Google.Protobuf.UInt32Value.t(),
          interval: Google.Protobuf.Duration.t(),
          base_ejection_time: Google.Protobuf.Duration.t(),
          max_ejection_percent: Google.Protobuf.UInt32Value.t(),
          enforcing_consecutive_5xx: Google.Protobuf.UInt32Value.t(),
          enforcing_success_rate: Google.Protobuf.UInt32Value.t(),
          success_rate_minimum_hosts: Google.Protobuf.UInt32Value.t(),
          success_rate_request_volume: Google.Protobuf.UInt32Value.t(),
          success_rate_stdev_factor: Google.Protobuf.UInt32Value.t(),
          consecutive_gateway_failure: Google.Protobuf.UInt32Value.t(),
          enforcing_consecutive_gateway_failure: Google.Protobuf.UInt32Value.t()
        }
  defstruct [
    :consecutive_5xx,
    :interval,
    :base_ejection_time,
    :max_ejection_percent,
    :enforcing_consecutive_5xx,
    :enforcing_success_rate,
    :success_rate_minimum_hosts,
    :success_rate_request_volume,
    :success_rate_stdev_factor,
    :consecutive_gateway_failure,
    :enforcing_consecutive_gateway_failure
  ]

  field :consecutive_5xx, 1, type: Google.Protobuf.UInt32Value
  field :interval, 2, type: Google.Protobuf.Duration
  field :base_ejection_time, 3, type: Google.Protobuf.Duration
  field :max_ejection_percent, 4, type: Google.Protobuf.UInt32Value
  field :enforcing_consecutive_5xx, 5, type: Google.Protobuf.UInt32Value
  field :enforcing_success_rate, 6, type: Google.Protobuf.UInt32Value
  field :success_rate_minimum_hosts, 7, type: Google.Protobuf.UInt32Value
  field :success_rate_request_volume, 8, type: Google.Protobuf.UInt32Value
  field :success_rate_stdev_factor, 9, type: Google.Protobuf.UInt32Value
  field :consecutive_gateway_failure, 10, type: Google.Protobuf.UInt32Value
  field :enforcing_consecutive_gateway_failure, 11, type: Google.Protobuf.UInt32Value
end
