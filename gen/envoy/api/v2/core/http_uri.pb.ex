defmodule Envoy.Api.V2.Core.HttpUri do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          http_upstream_type: {atom, any},
          uri: String.t()
        }
  defstruct [:http_upstream_type, :uri]

  oneof :http_upstream_type, 0
  field :uri, 1, type: :string
  field :cluster, 2, type: :string, oneof: 0
end
