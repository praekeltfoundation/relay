defmodule Envoy.Config.Retry.OtherPriority.OtherPriorityConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          update_frequency: integer
        }
  defstruct [:update_frequency]

  field :update_frequency, 1, type: :int32
end
