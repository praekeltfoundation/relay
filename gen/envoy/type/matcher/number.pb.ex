defmodule Envoy.Type.Matcher.DoubleMatcher do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          match_pattern: {atom, any}
        }
  defstruct [:match_pattern]

  oneof :match_pattern, 0
  field :range, 1, type: Envoy.Type.DoubleRange, oneof: 0
  field :exact, 2, type: :double, oneof: 0
end
