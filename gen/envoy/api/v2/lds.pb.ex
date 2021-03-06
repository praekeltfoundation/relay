defmodule Envoy.Api.V2.Listener do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          address: Envoy.Api.V2.Core.Address.t() | nil,
          filter_chains: [Envoy.Api.V2.Listener.FilterChain.t()],
          use_original_dst: Google.Protobuf.BoolValue.t() | nil,
          per_connection_buffer_limit_bytes: Google.Protobuf.UInt32Value.t() | nil,
          metadata: Envoy.Api.V2.Core.Metadata.t() | nil,
          deprecated_v1: Envoy.Api.V2.Listener.DeprecatedV1.t() | nil,
          drain_type: integer,
          listener_filters: [Envoy.Api.V2.Listener.ListenerFilter.t()],
          transparent: Google.Protobuf.BoolValue.t() | nil,
          freebind: Google.Protobuf.BoolValue.t() | nil,
          socket_options: [Envoy.Api.V2.Core.SocketOption.t()],
          tcp_fast_open_queue_length: Google.Protobuf.UInt32Value.t() | nil
        }
  defstruct [
    :name,
    :address,
    :filter_chains,
    :use_original_dst,
    :per_connection_buffer_limit_bytes,
    :metadata,
    :deprecated_v1,
    :drain_type,
    :listener_filters,
    :transparent,
    :freebind,
    :socket_options,
    :tcp_fast_open_queue_length
  ]

  field :name, 1, type: :string
  field :address, 2, type: Envoy.Api.V2.Core.Address
  field :filter_chains, 3, repeated: true, type: Envoy.Api.V2.Listener.FilterChain
  field :use_original_dst, 4, type: Google.Protobuf.BoolValue, deprecated: true
  field :per_connection_buffer_limit_bytes, 5, type: Google.Protobuf.UInt32Value
  field :metadata, 6, type: Envoy.Api.V2.Core.Metadata
  field :deprecated_v1, 7, type: Envoy.Api.V2.Listener.DeprecatedV1
  field :drain_type, 8, type: Envoy.Api.V2.Listener.DrainType, enum: true
  field :listener_filters, 9, repeated: true, type: Envoy.Api.V2.Listener.ListenerFilter
  field :transparent, 10, type: Google.Protobuf.BoolValue
  field :freebind, 11, type: Google.Protobuf.BoolValue
  field :socket_options, 13, repeated: true, type: Envoy.Api.V2.Core.SocketOption
  field :tcp_fast_open_queue_length, 12, type: Google.Protobuf.UInt32Value
end

defmodule Envoy.Api.V2.Listener.DeprecatedV1 do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          bind_to_port: Google.Protobuf.BoolValue.t() | nil
        }
  defstruct [:bind_to_port]

  field :bind_to_port, 1, type: Google.Protobuf.BoolValue
end

defmodule Envoy.Api.V2.Listener.DrainType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :DEFAULT, 0
  field :MODIFY_ONLY, 1
end

defmodule Envoy.Api.V2.ListenerDiscoveryService.Service do
  @moduledoc false
  use GRPC.Service, name: "envoy.api.v2.ListenerDiscoveryService"

  rpc :StreamListeners,
      stream(Envoy.Api.V2.DiscoveryRequest),
      stream(Envoy.Api.V2.DiscoveryResponse)

  rpc :FetchListeners, Envoy.Api.V2.DiscoveryRequest, Envoy.Api.V2.DiscoveryResponse
end

defmodule Envoy.Api.V2.ListenerDiscoveryService.Stub do
  @moduledoc false
  use GRPC.Stub, service: Envoy.Api.V2.ListenerDiscoveryService.Service
end
