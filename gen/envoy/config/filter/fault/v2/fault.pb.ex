defmodule Envoy.Config.Filter.Fault.V2.FaultDelay do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          fault_delay_secifier: {atom, any},
          type: integer,
          percent: non_neg_integer,
          percentage: Envoy.Type.FractionalPercent.t()
        }
  defstruct [:fault_delay_secifier, :type, :percent, :percentage]

  oneof :fault_delay_secifier, 0
  field :type, 1, type: Envoy.Config.Filter.Fault.V2.FaultDelay.FaultDelayType, enum: true
  field :percent, 2, type: :uint32, deprecated: true
  field :fixed_delay, 3, type: Google.Protobuf.Duration, oneof: 0
  field :percentage, 4, type: Envoy.Type.FractionalPercent
end

defmodule Envoy.Config.Filter.Fault.V2.FaultDelay.FaultDelayType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :FIXED, 0
end
