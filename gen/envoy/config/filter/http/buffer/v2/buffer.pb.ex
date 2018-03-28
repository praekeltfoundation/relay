defmodule Envoy.Config.Filter.Http.Buffer.V2.Buffer do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          max_request_bytes: Google.Protobuf.UInt32Value.t(),
          max_request_time: Google.Protobuf.Duration.t()
        }
  defstruct [:max_request_bytes, :max_request_time]

  field :max_request_bytes, 1, type: Google.Protobuf.UInt32Value
  field :max_request_time, 2, type: Google.Protobuf.Duration
end
