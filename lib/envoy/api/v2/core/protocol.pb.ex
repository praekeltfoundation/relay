defmodule Envoy.Api.V2.Core.TcpProtocolOptions do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule Envoy.Api.V2.Core.Http1ProtocolOptions do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          allow_absolute_url: Google.Protobuf.BoolValue.t()
        }
  defstruct [:allow_absolute_url]

  field :allow_absolute_url, 1, type: Google.Protobuf.BoolValue
end

defmodule Envoy.Api.V2.Core.Http2ProtocolOptions do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          hpack_table_size: Google.Protobuf.UInt32Value.t(),
          max_concurrent_streams: Google.Protobuf.UInt32Value.t(),
          initial_stream_window_size: Google.Protobuf.UInt32Value.t(),
          initial_connection_window_size: Google.Protobuf.UInt32Value.t()
        }
  defstruct [
    :hpack_table_size,
    :max_concurrent_streams,
    :initial_stream_window_size,
    :initial_connection_window_size
  ]

  field :hpack_table_size, 1, type: Google.Protobuf.UInt32Value
  field :max_concurrent_streams, 2, type: Google.Protobuf.UInt32Value
  field :initial_stream_window_size, 3, type: Google.Protobuf.UInt32Value
  field :initial_connection_window_size, 4, type: Google.Protobuf.UInt32Value
end

defmodule Envoy.Api.V2.Core.GrpcProtocolOptions do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          http2_protocol_options: Envoy.Api.V2.Core.Http2ProtocolOptions.t()
        }
  defstruct [:http2_protocol_options]

  field :http2_protocol_options, 1, type: Envoy.Api.V2.Core.Http2ProtocolOptions
end
