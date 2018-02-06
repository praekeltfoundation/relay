defmodule Envoy.Config.Filter.Http.Squash.V2.Squash do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    cluster:                String.t,
    attachment_template:    Google.Protobuf.Struct.t,
    request_timeout:        Google.Protobuf.Duration.t,
    attachment_timeout:     Google.Protobuf.Duration.t,
    attachment_poll_period: Google.Protobuf.Duration.t
  }
  defstruct [:cluster, :attachment_template, :request_timeout, :attachment_timeout, :attachment_poll_period]

  field :cluster, 1, type: :string
  field :attachment_template, 2, type: Google.Protobuf.Struct
  field :request_timeout, 3, type: Google.Protobuf.Duration
  field :attachment_timeout, 4, type: Google.Protobuf.Duration
  field :attachment_poll_period, 5, type: Google.Protobuf.Duration
end
