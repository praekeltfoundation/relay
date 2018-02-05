defmodule Envoy.Api.V2.Filter.Http.ExtAuthz do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    grpc_service:       Envoy.Api.V2.GrpcService.t,
    failure_mode_allow: boolean
  }
  defstruct [:grpc_service, :failure_mode_allow]

  field :grpc_service, 1, type: Envoy.Api.V2.GrpcService
  field :failure_mode_allow, 2, type: :bool
end
