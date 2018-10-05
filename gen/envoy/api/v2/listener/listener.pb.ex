defmodule Envoy.Api.V2.Listener.Filter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          config: Google.Protobuf.Struct.t(),
          deprecated_v1: Envoy.Api.V2.Listener.Filter.DeprecatedV1.t()
        }
  defstruct [:name, :config, :deprecated_v1]

  field :name, 1, type: :string
  field :config, 2, type: Google.Protobuf.Struct
  field :deprecated_v1, 3, type: Envoy.Api.V2.Listener.Filter.DeprecatedV1, deprecated: true
end

defmodule Envoy.Api.V2.Listener.Filter.DeprecatedV1 do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          type: String.t()
        }
  defstruct [:type]

  field :type, 1, type: :string
end

defmodule Envoy.Api.V2.Listener.FilterChainMatch do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          destination_port: Google.Protobuf.UInt32Value.t(),
          prefix_ranges: [Envoy.Api.V2.Core.CidrRange.t()],
          address_suffix: String.t(),
          suffix_len: Google.Protobuf.UInt32Value.t(),
          source_prefix_ranges: [Envoy.Api.V2.Core.CidrRange.t()],
          source_ports: [Google.Protobuf.UInt32Value.t()],
          server_names: [String.t()],
          transport_protocol: String.t(),
          application_protocols: [String.t()]
        }
  defstruct [
    :destination_port,
    :prefix_ranges,
    :address_suffix,
    :suffix_len,
    :source_prefix_ranges,
    :source_ports,
    :server_names,
    :transport_protocol,
    :application_protocols
  ]

  field :destination_port, 8, type: Google.Protobuf.UInt32Value
  field :prefix_ranges, 3, repeated: true, type: Envoy.Api.V2.Core.CidrRange
  field :address_suffix, 4, type: :string
  field :suffix_len, 5, type: Google.Protobuf.UInt32Value
  field :source_prefix_ranges, 6, repeated: true, type: Envoy.Api.V2.Core.CidrRange
  field :source_ports, 7, repeated: true, type: Google.Protobuf.UInt32Value
  field :server_names, 11, repeated: true, type: :string
  field :transport_protocol, 9, type: :string
  field :application_protocols, 10, repeated: true, type: :string
end

defmodule Envoy.Api.V2.Listener.FilterChain do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filter_chain_match: Envoy.Api.V2.Listener.FilterChainMatch.t(),
          tls_context: Envoy.Api.V2.Auth.DownstreamTlsContext.t(),
          filters: [Envoy.Api.V2.Listener.Filter.t()],
          use_proxy_proto: Google.Protobuf.BoolValue.t(),
          metadata: Envoy.Api.V2.Core.Metadata.t(),
          transport_socket: Envoy.Api.V2.Core.TransportSocket.t()
        }
  defstruct [
    :filter_chain_match,
    :tls_context,
    :filters,
    :use_proxy_proto,
    :metadata,
    :transport_socket
  ]

  field :filter_chain_match, 1, type: Envoy.Api.V2.Listener.FilterChainMatch
  field :tls_context, 2, type: Envoy.Api.V2.Auth.DownstreamTlsContext
  field :filters, 3, repeated: true, type: Envoy.Api.V2.Listener.Filter
  field :use_proxy_proto, 4, type: Google.Protobuf.BoolValue
  field :metadata, 5, type: Envoy.Api.V2.Core.Metadata
  field :transport_socket, 6, type: Envoy.Api.V2.Core.TransportSocket
end

defmodule Envoy.Api.V2.Listener.ListenerFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          config: Google.Protobuf.Struct.t()
        }
  defstruct [:name, :config]

  field :name, 1, type: :string
  field :config, 2, type: Google.Protobuf.Struct
end
