defmodule Envoy.Type.StringMatch do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          match_pattern: {atom, any}
        }
  defstruct [:match_pattern]

  oneof :match_pattern, 0
  field :simple, 1, type: :string, oneof: 0
  field :prefix, 2, type: :string, oneof: 0
  field :suffix, 3, type: :string, oneof: 0
  field :regex, 4, type: :string, oneof: 0
end
