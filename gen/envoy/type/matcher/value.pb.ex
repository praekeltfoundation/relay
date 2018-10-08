defmodule Envoy.Type.Matcher.ValueMatcher do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          match_pattern: {atom, any}
        }
  defstruct [:match_pattern]

  oneof :match_pattern, 0
  field :null_match, 1, type: Envoy.Type.Matcher.ValueMatcher.NullMatch, oneof: 0
  field :double_match, 2, type: Envoy.Type.Matcher.DoubleMatcher, oneof: 0
  field :string_match, 3, type: Envoy.Type.Matcher.StringMatcher, oneof: 0
  field :bool_match, 4, type: :bool, oneof: 0
  field :present_match, 5, type: :bool, oneof: 0
  field :list_match, 6, type: Envoy.Type.Matcher.ListMatcher, oneof: 0
end

defmodule Envoy.Type.Matcher.ValueMatcher.NullMatch do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []
end

defmodule Envoy.Type.Matcher.ListMatcher do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          match_pattern: {atom, any}
        }
  defstruct [:match_pattern]

  oneof :match_pattern, 0
  field :one_of, 1, type: Envoy.Type.Matcher.ValueMatcher, oneof: 0
end
