defmodule Envoy.Config.ResourceMonitor.FixedHeap.V2alpha.FixedHeapConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          max_heap_size_bytes: non_neg_integer
        }
  defstruct [:max_heap_size_bytes]

  field :max_heap_size_bytes, 1, type: :uint64
end
