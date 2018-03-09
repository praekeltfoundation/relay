defmodule Envoy.Type.Percent do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          value: float
        }
  defstruct [:value]

  field :value, 1, type: :double
end

defmodule Envoy.Type.FractionalPercent do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          numerator: non_neg_integer,
          denominator: integer
        }
  defstruct [:numerator, :denominator]

  field :numerator, 1, type: :uint32
  field :denominator, 2, type: Envoy.Type.FractionalPercent.DenominatorType, enum: true
end

defmodule Envoy.Type.FractionalPercent.DenominatorType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :HUNDRED, 0
  field :TEN_THOUSAND, 1
  field :MILLION, 2
end
