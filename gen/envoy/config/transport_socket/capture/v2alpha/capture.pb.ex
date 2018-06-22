defmodule Envoy.Config.TransportSocket.Capture.V2alpha.FileSink do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          path_prefix: String.t(),
          format: integer
        }
  defstruct [:path_prefix, :format]

  field :path_prefix, 1, type: :string
  field :format, 2, type: Envoy.Config.TransportSocket.Capture.V2alpha.FileSink.Format, enum: true
end

defmodule Envoy.Config.TransportSocket.Capture.V2alpha.FileSink.Format do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :PROTO_BINARY, 0
  field :PROTO_TEXT, 1
end

defmodule Envoy.Config.TransportSocket.Capture.V2alpha.Capture do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          sink_selector: {atom, any},
          transport_socket: Envoy.Api.V2.Core.TransportSocket.t()
        }
  defstruct [:sink_selector, :transport_socket]

  oneof :sink_selector, 0
  field :file_sink, 1, type: Envoy.Config.TransportSocket.Capture.V2alpha.FileSink, oneof: 0
  field :transport_socket, 2, type: Envoy.Api.V2.Core.TransportSocket
end
