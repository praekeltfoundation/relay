defmodule Envoy.Config.Filter.Http.ExtAuthz.V2.ExtAuthz do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          grpc_service: Envoy.Api.V2.Core.GrpcService.t(),
          failure_mode_allow: boolean
        }
  defstruct [:grpc_service, :failure_mode_allow]

  field :grpc_service, 1, type: Envoy.Api.V2.Core.GrpcService
  field :failure_mode_allow, 2, type: :bool
end
