defmodule Envoy.Api.V2.Filter.Network.ExtAuthz do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    stat_prefix:        String.t,
    grpc_service:       Envoy.Api.V2.GrpcService.t,
    failure_mode_allow: boolean
  }
  defstruct [:stat_prefix, :grpc_service, :failure_mode_allow]

  field :stat_prefix, 1, type: :string
  field :grpc_service, 2, type: Envoy.Api.V2.GrpcService
  field :failure_mode_allow, 3, type: :bool
end
