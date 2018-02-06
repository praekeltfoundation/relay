defmodule Envoy.Config.Filter.Network.RedisProxy.V2.RedisProxy do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    stat_prefix: String.t,
    cluster:     String.t,
    settings:    Envoy.Config.Filter.Network.RedisProxy.V2.RedisProxy.ConnPoolSettings.t
  }
  defstruct [:stat_prefix, :cluster, :settings]

  field :stat_prefix, 1, type: :string
  field :cluster, 2, type: :string
  field :settings, 3, type: Envoy.Config.Filter.Network.RedisProxy.V2.RedisProxy.ConnPoolSettings
end

defmodule Envoy.Config.Filter.Network.RedisProxy.V2.RedisProxy.ConnPoolSettings do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    op_timeout: Google.Protobuf.Duration.t
  }
  defstruct [:op_timeout]

  field :op_timeout, 1, type: Google.Protobuf.Duration
end