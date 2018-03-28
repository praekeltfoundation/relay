defmodule Envoy.Config.Filter.Fault.V2.FaultDelay do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          fault_delay_secifier: {atom, any},
          type: integer,
          percent: non_neg_integer
        }
  defstruct [:fault_delay_secifier, :type, :percent]

  oneof :fault_delay_secifier, 0
  field :type, 1, type: Envoy.Config.Filter.Fault.V2.FaultDelay.FaultDelayType, enum: true
  field :percent, 2, type: :uint32
  field :fixed_delay, 3, type: Google.Protobuf.Duration, oneof: 0
end

defmodule Envoy.Config.Filter.Fault.V2.FaultDelay.FaultDelayType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :FIXED, 0
end
