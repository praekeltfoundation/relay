defmodule Envoy.Api.V2.Filter.Http.Lua do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    inline_code: String.t
  }
  defstruct [:inline_code]

  field :inline_code, 1, type: :string
end
