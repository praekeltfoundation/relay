defmodule Envoy.Config.Filter.Network.RateLimit.V2.RateLimit do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    stat_prefix: String.t,
    domain:      String.t,
    descriptors: [Envoy.Api.V2.Ratelimit.RateLimitDescriptor.t],
    timeout:     Google.Protobuf.Duration.t
  }
  defstruct [:stat_prefix, :domain, :descriptors, :timeout]

  field :stat_prefix, 1, type: :string
  field :domain, 2, type: :string
  field :descriptors, 3, repeated: true, type: Envoy.Api.V2.Ratelimit.RateLimitDescriptor
  field :timeout, 4, type: Google.Protobuf.Duration
end
