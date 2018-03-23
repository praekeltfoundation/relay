defmodule Envoy.Config.Metrics.V2.MetricsServiceConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          grpc_service: Envoy.Api.V2.Core.GrpcService.t()
        }
  defstruct [:grpc_service]

  field :grpc_service, 1, type: Envoy.Api.V2.Core.GrpcService
end
