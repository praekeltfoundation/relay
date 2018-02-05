defmodule Envoy.Api.V2.Filter.Network.MongoProxy do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    stat_prefix: String.t,
    access_log:  String.t,
    delay:       Envoy.Api.V2.Filter.FaultDelay.t
  }
  defstruct [:stat_prefix, :access_log, :delay]

  field :stat_prefix, 1, type: :string
  field :access_log, 2, type: :string
  field :delay, 3, type: Envoy.Api.V2.Filter.FaultDelay
end
