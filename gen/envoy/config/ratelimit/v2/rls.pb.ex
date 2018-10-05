defmodule Envoy.Config.Ratelimit.V2.RateLimitServiceConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          service_specifier: {atom, any},
          use_data_plane_proto: boolean
        }
  defstruct [:service_specifier, :use_data_plane_proto]

  oneof :service_specifier, 0
  field :cluster_name, 1, type: :string, deprecated: true, oneof: 0
  field :grpc_service, 2, type: Envoy.Api.V2.Core.GrpcService, oneof: 0
  field :use_data_plane_proto, 3, type: :bool, deprecated: true
end
