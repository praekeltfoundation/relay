defmodule Envoy.Config.Filter.Http.Lua.V2.Lua do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          inline_code: String.t()
        }
  defstruct [:inline_code]

  field :inline_code, 1, type: :string
end
