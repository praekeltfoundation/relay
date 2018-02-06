defmodule Envoy.Config.Filter.Fault.V2.FaultDelay do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    fault_delay_type: {atom, any},
    type:        integer,
    percent:     non_neg_integer
  }
  defstruct [:fault_delay_type, :type, :percent]

  oneof :fault_delay_type, 0
  field :type, 1, type: Envoy.Config.Filter.Fault.V2.FaultDelay.FaultDelayType, enum: true
  field :percent, 2, type: :uint32
  field :fixed_delay, 3, type: Google.Protobuf.Duration, oneof: 0
end

defmodule Envoy.Config.Filter.Fault.V2.FaultDelay.FaultDelayType do
  use Protobuf, enum: true, syntax: :proto3

  field :FIXED, 0
end
