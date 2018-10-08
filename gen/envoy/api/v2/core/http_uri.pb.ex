defmodule Envoy.Api.V2.Core.HttpUri do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          http_upstream_type: {atom, any},
          uri: String.t(),
          timeout: Google.Protobuf.Duration.t() | nil
        }
  defstruct [:http_upstream_type, :uri, :timeout]

  oneof :http_upstream_type, 0
  field :uri, 1, type: :string
  field :cluster, 2, type: :string, oneof: 0
  field :timeout, 3, type: Google.Protobuf.Duration
end
