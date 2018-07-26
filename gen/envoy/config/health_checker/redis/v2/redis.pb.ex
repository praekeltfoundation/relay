defmodule Envoy.Config.HealthChecker.Redis.V2.Redis do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t()
        }
  defstruct [:key]

  field :key, 1, type: :string
end
