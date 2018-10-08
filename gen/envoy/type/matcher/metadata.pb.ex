defmodule Envoy.Type.Matcher.MetadataMatcher do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filter: String.t(),
          path: [Envoy.Type.Matcher.MetadataMatcher.PathSegment.t()],
          value: Envoy.Type.Matcher.ValueMatcher.t() | nil
        }
  defstruct [:filter, :path, :value]

  field :filter, 1, type: :string
  field :path, 2, repeated: true, type: Envoy.Type.Matcher.MetadataMatcher.PathSegment
  field :value, 3, type: Envoy.Type.Matcher.ValueMatcher
end

defmodule Envoy.Type.Matcher.MetadataMatcher.PathSegment do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          segment: {atom, any}
        }
  defstruct [:segment]

  oneof :segment, 0
  field :key, 1, type: :string, oneof: 0
end
