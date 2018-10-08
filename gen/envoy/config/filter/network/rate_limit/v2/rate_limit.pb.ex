defmodule Envoy.Config.Filter.Network.RateLimit.V2.RateLimit do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          stat_prefix: String.t(),
          domain: String.t(),
          descriptors: [Envoy.Api.V2.Ratelimit.RateLimitDescriptor.t()],
          timeout: Google.Protobuf.Duration.t() | nil,
          failure_mode_deny: boolean
        }
  defstruct [:stat_prefix, :domain, :descriptors, :timeout, :failure_mode_deny]

  field :stat_prefix, 1, type: :string
  field :domain, 2, type: :string
  field :descriptors, 3, repeated: true, type: Envoy.Api.V2.Ratelimit.RateLimitDescriptor
  field :timeout, 4, type: Google.Protobuf.Duration
  field :failure_mode_deny, 5, type: :bool
end
