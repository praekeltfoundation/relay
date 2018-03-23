defmodule Envoy.Api.V2.Ratelimit.RateLimitDescriptor do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          entries: [Envoy.Api.V2.Ratelimit.RateLimitDescriptor.Entry.t()]
        }
  defstruct [:entries]

  field :entries, 1, repeated: true, type: Envoy.Api.V2.Ratelimit.RateLimitDescriptor.Entry
end

defmodule Envoy.Api.V2.Ratelimit.RateLimitDescriptor.Entry do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end
