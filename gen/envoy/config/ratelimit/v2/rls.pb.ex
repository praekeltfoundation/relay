defmodule Envoy.Config.Ratelimit.V2.RateLimitServiceConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          service_specifier: {atom, any}
        }
  defstruct [:service_specifier]

  oneof :service_specifier, 0
  field :cluster_name, 1, type: :string, deprecated: true, oneof: 0
  field :grpc_service, 2, type: Envoy.Api.V2.Core.GrpcService, oneof: 0
end
