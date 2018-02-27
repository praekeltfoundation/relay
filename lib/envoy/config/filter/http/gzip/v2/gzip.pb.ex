defmodule Envoy.Config.Filter.Http.Gzip.V2.Gzip do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    memory_level:                  Google.Protobuf.UInt32Value.t,
    content_length:                Google.Protobuf.UInt32Value.t,
    compression_level:             integer,
    compression_strategy:          integer,
    content_type:                  [String.t],
    disable_on_etag_header:        boolean,
    remove_accept_encoding_header: boolean,
    window_bits:                   Google.Protobuf.UInt32Value.t
  }
  defstruct [:memory_level, :content_length, :compression_level, :compression_strategy, :content_type, :disable_on_etag_header, :remove_accept_encoding_header, :window_bits]

  field :memory_level, 1, type: Google.Protobuf.UInt32Value
  field :content_length, 2, type: Google.Protobuf.UInt32Value
  field :compression_level, 3, type: Envoy.Config.Filter.Http.Gzip.V2.Gzip.CompressionLevel.Enum, enum: true
  field :compression_strategy, 4, type: Envoy.Config.Filter.Http.Gzip.V2.Gzip.CompressionStrategy, enum: true
  field :content_type, 6, repeated: true, type: :string
  field :disable_on_etag_header, 7, type: :bool
  field :remove_accept_encoding_header, 8, type: :bool
  field :window_bits, 9, type: Google.Protobuf.UInt32Value
end

defmodule Envoy.Config.Filter.Http.Gzip.V2.Gzip.CompressionLevel do
  use Protobuf, syntax: :proto3

  defstruct []

end

defmodule Envoy.Config.Filter.Http.Gzip.V2.Gzip.CompressionLevel.Enum do
  use Protobuf, enum: true, syntax: :proto3

  field :DEFAULT, 0
  field :BEST, 1
  field :SPEED, 2
end

defmodule Envoy.Config.Filter.Http.Gzip.V2.Gzip.CompressionStrategy do
  use Protobuf, enum: true, syntax: :proto3

  field :DEFAULT, 0
  field :FILTERED, 1
  field :HUFFMAN, 2
  field :RLE, 3
end
