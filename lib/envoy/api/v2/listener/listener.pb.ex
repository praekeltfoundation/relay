defmodule Envoy.Api.V2.Listener.Filter do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    name:          String.t,
    config:        Google.Protobuf.Struct.t,
    deprecated_v1: Envoy.Api.V2.Listener.Filter.DeprecatedV1.t
  }
  defstruct [:name, :config, :deprecated_v1]

  field :name, 1, type: :string
  field :config, 2, type: Google.Protobuf.Struct
  field :deprecated_v1, 3, type: Envoy.Api.V2.Listener.Filter.DeprecatedV1, deprecated: true
end

defmodule Envoy.Api.V2.Listener.Filter.DeprecatedV1 do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    type: String.t
  }
  defstruct [:type]

  field :type, 1, type: :string
end

defmodule Envoy.Api.V2.Listener.FilterChainMatch do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    sni_domains:          [String.t],
    prefix_ranges:        [Envoy.Api.V2.CidrRange.t],
    address_suffix:       String.t,
    suffix_len:           Google.Protobuf.UInt32Value.t,
    source_prefix_ranges: [Envoy.Api.V2.CidrRange.t],
    source_ports:         [Google.Protobuf.UInt32Value.t],
    destination_port:     Google.Protobuf.UInt32Value.t
  }
  defstruct [:sni_domains, :prefix_ranges, :address_suffix, :suffix_len, :source_prefix_ranges, :source_ports, :destination_port]

  field :sni_domains, 1, repeated: true, type: :string
  field :prefix_ranges, 3, repeated: true, type: Envoy.Api.V2.CidrRange
  field :address_suffix, 4, type: :string
  field :suffix_len, 5, type: Google.Protobuf.UInt32Value
  field :source_prefix_ranges, 6, repeated: true, type: Envoy.Api.V2.CidrRange
  field :source_ports, 7, repeated: true, type: Google.Protobuf.UInt32Value
  field :destination_port, 8, type: Google.Protobuf.UInt32Value
end

defmodule Envoy.Api.V2.Listener.FilterChain do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    filter_chain_match: Envoy.Api.V2.Listener.FilterChainMatch.t,
    tls_context:        Envoy.Api.V2.Auth.DownstreamTlsContext.t,
    filters:            [Envoy.Api.V2.Listener.Filter.t],
    use_proxy_proto:    Google.Protobuf.BoolValue.t,
    metadata:           Envoy.Api.V2.Metadata.t,
    transport_socket:   Envoy.Api.V2.TransportSocket.t
  }
  defstruct [:filter_chain_match, :tls_context, :filters, :use_proxy_proto, :metadata, :transport_socket]

  field :filter_chain_match, 1, type: Envoy.Api.V2.Listener.FilterChainMatch
  field :tls_context, 2, type: Envoy.Api.V2.Auth.DownstreamTlsContext
  field :filters, 3, repeated: true, type: Envoy.Api.V2.Listener.Filter
  field :use_proxy_proto, 4, type: Google.Protobuf.BoolValue
  field :metadata, 5, type: Envoy.Api.V2.Metadata
  field :transport_socket, 6, type: Envoy.Api.V2.TransportSocket
end

defmodule Envoy.Api.V2.Listener.ListenerFilter do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    name:   String.t,
    config: Google.Protobuf.Struct.t
  }
  defstruct [:name, :config]

  field :name, 1, type: :string
  field :config, 2, type: Google.Protobuf.Struct
end
