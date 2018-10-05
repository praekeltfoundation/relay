defmodule Envoy.Config.Filter.Http.RateLimit.V2.RateLimit do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          domain: String.t(),
          stage: non_neg_integer,
          request_type: String.t(),
          timeout: Google.Protobuf.Duration.t(),
          failure_mode_deny: boolean
        }
  defstruct [:domain, :stage, :request_type, :timeout, :failure_mode_deny]

  field :domain, 1, type: :string
  field :stage, 2, type: :uint32
  field :request_type, 3, type: :string
  field :timeout, 4, type: Google.Protobuf.Duration
  field :failure_mode_deny, 5, type: :bool
end
