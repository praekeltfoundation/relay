defmodule Envoy.Api.V2.Cluster do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          lb_config: {atom, any},
          name: String.t(),
          alt_stat_name: String.t(),
          type: integer,
          eds_cluster_config: Envoy.Api.V2.Cluster.EdsClusterConfig.t() | nil,
          connect_timeout: Google.Protobuf.Duration.t() | nil,
          per_connection_buffer_limit_bytes: Google.Protobuf.UInt32Value.t() | nil,
          lb_policy: integer,
          hosts: [Envoy.Api.V2.Core.Address.t()],
          load_assignment: Envoy.Api.V2.ClusterLoadAssignment.t() | nil,
          health_checks: [Envoy.Api.V2.Core.HealthCheck.t()],
          max_requests_per_connection: Google.Protobuf.UInt32Value.t() | nil,
          circuit_breakers: Envoy.Api.V2.Cluster.CircuitBreakers.t() | nil,
          tls_context: Envoy.Api.V2.Auth.UpstreamTlsContext.t() | nil,
          common_http_protocol_options: Envoy.Api.V2.Core.HttpProtocolOptions.t() | nil,
          http_protocol_options: Envoy.Api.V2.Core.Http1ProtocolOptions.t() | nil,
          http2_protocol_options: Envoy.Api.V2.Core.Http2ProtocolOptions.t() | nil,
          extension_protocol_options: %{String.t() => Google.Protobuf.Struct.t() | nil},
          dns_refresh_rate: Google.Protobuf.Duration.t() | nil,
          dns_lookup_family: integer,
          dns_resolvers: [Envoy.Api.V2.Core.Address.t()],
          outlier_detection: Envoy.Api.V2.Cluster.OutlierDetection.t() | nil,
          cleanup_interval: Google.Protobuf.Duration.t() | nil,
          upstream_bind_config: Envoy.Api.V2.Core.BindConfig.t() | nil,
          lb_subset_config: Envoy.Api.V2.Cluster.LbSubsetConfig.t() | nil,
          common_lb_config: Envoy.Api.V2.Cluster.CommonLbConfig.t() | nil,
          transport_socket: Envoy.Api.V2.Core.TransportSocket.t() | nil,
          metadata: Envoy.Api.V2.Core.Metadata.t() | nil,
          protocol_selection: integer,
          upstream_connection_options: Envoy.Api.V2.UpstreamConnectionOptions.t() | nil,
          close_connections_on_host_health_failure: boolean,
          drain_connections_on_host_removal: boolean
        }
  defstruct [
    :lb_config,
    :name,
    :alt_stat_name,
    :type,
    :eds_cluster_config,
    :connect_timeout,
    :per_connection_buffer_limit_bytes,
    :lb_policy,
    :hosts,
    :load_assignment,
    :health_checks,
    :max_requests_per_connection,
    :circuit_breakers,
    :tls_context,
    :common_http_protocol_options,
    :http_protocol_options,
    :http2_protocol_options,
    :extension_protocol_options,
    :dns_refresh_rate,
    :dns_lookup_family,
    :dns_resolvers,
    :outlier_detection,
    :cleanup_interval,
    :upstream_bind_config,
    :lb_subset_config,
    :common_lb_config,
    :transport_socket,
    :metadata,
    :protocol_selection,
    :upstream_connection_options,
    :close_connections_on_host_health_failure,
    :drain_connections_on_host_removal
  ]

  oneof :lb_config, 0
  field :name, 1, type: :string
  field :alt_stat_name, 28, type: :string
  field :type, 2, type: Envoy.Api.V2.Cluster.DiscoveryType, enum: true
  field :eds_cluster_config, 3, type: Envoy.Api.V2.Cluster.EdsClusterConfig
  field :connect_timeout, 4, type: Google.Protobuf.Duration
  field :per_connection_buffer_limit_bytes, 5, type: Google.Protobuf.UInt32Value
  field :lb_policy, 6, type: Envoy.Api.V2.Cluster.LbPolicy, enum: true
  field :hosts, 7, repeated: true, type: Envoy.Api.V2.Core.Address, deprecated: true
  field :load_assignment, 33, type: Envoy.Api.V2.ClusterLoadAssignment
  field :health_checks, 8, repeated: true, type: Envoy.Api.V2.Core.HealthCheck
  field :max_requests_per_connection, 9, type: Google.Protobuf.UInt32Value
  field :circuit_breakers, 10, type: Envoy.Api.V2.Cluster.CircuitBreakers
  field :tls_context, 11, type: Envoy.Api.V2.Auth.UpstreamTlsContext
  field :common_http_protocol_options, 29, type: Envoy.Api.V2.Core.HttpProtocolOptions
  field :http_protocol_options, 13, type: Envoy.Api.V2.Core.Http1ProtocolOptions
  field :http2_protocol_options, 14, type: Envoy.Api.V2.Core.Http2ProtocolOptions

  field :extension_protocol_options, 35,
    repeated: true,
    type: Envoy.Api.V2.Cluster.ExtensionProtocolOptionsEntry,
    map: true

  field :dns_refresh_rate, 16, type: Google.Protobuf.Duration
  field :dns_lookup_family, 17, type: Envoy.Api.V2.Cluster.DnsLookupFamily, enum: true
  field :dns_resolvers, 18, repeated: true, type: Envoy.Api.V2.Core.Address
  field :outlier_detection, 19, type: Envoy.Api.V2.Cluster.OutlierDetection
  field :cleanup_interval, 20, type: Google.Protobuf.Duration
  field :upstream_bind_config, 21, type: Envoy.Api.V2.Core.BindConfig
  field :lb_subset_config, 22, type: Envoy.Api.V2.Cluster.LbSubsetConfig
  field :ring_hash_lb_config, 23, type: Envoy.Api.V2.Cluster.RingHashLbConfig, oneof: 0
  field :original_dst_lb_config, 34, type: Envoy.Api.V2.Cluster.OriginalDstLbConfig, oneof: 0
  field :common_lb_config, 27, type: Envoy.Api.V2.Cluster.CommonLbConfig
  field :transport_socket, 24, type: Envoy.Api.V2.Core.TransportSocket
  field :metadata, 25, type: Envoy.Api.V2.Core.Metadata
  field :protocol_selection, 26, type: Envoy.Api.V2.Cluster.ClusterProtocolSelection, enum: true
  field :upstream_connection_options, 30, type: Envoy.Api.V2.UpstreamConnectionOptions
  field :close_connections_on_host_health_failure, 31, type: :bool
  field :drain_connections_on_host_removal, 32, type: :bool
end

defmodule Envoy.Api.V2.Cluster.EdsClusterConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          eds_config: Envoy.Api.V2.Core.ConfigSource.t() | nil,
          service_name: String.t()
        }
  defstruct [:eds_config, :service_name]

  field :eds_config, 1, type: Envoy.Api.V2.Core.ConfigSource
  field :service_name, 2, type: :string
end

defmodule Envoy.Api.V2.Cluster.ExtensionProtocolOptionsEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Google.Protobuf.Struct.t() | nil
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Google.Protobuf.Struct
end

defmodule Envoy.Api.V2.Cluster.LbSubsetConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          fallback_policy: integer,
          default_subset: Google.Protobuf.Struct.t() | nil,
          subset_selectors: [Envoy.Api.V2.Cluster.LbSubsetConfig.LbSubsetSelector.t()],
          locality_weight_aware: boolean
        }
  defstruct [:fallback_policy, :default_subset, :subset_selectors, :locality_weight_aware]

  field :fallback_policy, 1,
    type: Envoy.Api.V2.Cluster.LbSubsetConfig.LbSubsetFallbackPolicy,
    enum: true

  field :default_subset, 2, type: Google.Protobuf.Struct

  field :subset_selectors, 3,
    repeated: true,
    type: Envoy.Api.V2.Cluster.LbSubsetConfig.LbSubsetSelector

  field :locality_weight_aware, 4, type: :bool
end

defmodule Envoy.Api.V2.Cluster.LbSubsetConfig.LbSubsetSelector do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          keys: [String.t()]
        }
  defstruct [:keys]

  field :keys, 1, repeated: true, type: :string
end

defmodule Envoy.Api.V2.Cluster.LbSubsetConfig.LbSubsetFallbackPolicy do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :NO_FALLBACK, 0
  field :ANY_ENDPOINT, 1
  field :DEFAULT_SUBSET, 2
end

defmodule Envoy.Api.V2.Cluster.RingHashLbConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          minimum_ring_size: Google.Protobuf.UInt64Value.t() | nil,
          deprecated_v1: Envoy.Api.V2.Cluster.RingHashLbConfig.DeprecatedV1.t() | nil
        }
  defstruct [:minimum_ring_size, :deprecated_v1]

  field :minimum_ring_size, 1, type: Google.Protobuf.UInt64Value

  field :deprecated_v1, 2,
    type: Envoy.Api.V2.Cluster.RingHashLbConfig.DeprecatedV1,
    deprecated: true
end

defmodule Envoy.Api.V2.Cluster.RingHashLbConfig.DeprecatedV1 do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          use_std_hash: Google.Protobuf.BoolValue.t() | nil
        }
  defstruct [:use_std_hash]

  field :use_std_hash, 1, type: Google.Protobuf.BoolValue
end

defmodule Envoy.Api.V2.Cluster.OriginalDstLbConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          use_http_header: boolean
        }
  defstruct [:use_http_header]

  field :use_http_header, 1, type: :bool
end

defmodule Envoy.Api.V2.Cluster.CommonLbConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          locality_config_specifier: {atom, any},
          healthy_panic_threshold: Envoy.Type.Percent.t() | nil,
          update_merge_window: Google.Protobuf.Duration.t() | nil
        }
  defstruct [:locality_config_specifier, :healthy_panic_threshold, :update_merge_window]

  oneof :locality_config_specifier, 0
  field :healthy_panic_threshold, 1, type: Envoy.Type.Percent

  field :zone_aware_lb_config, 2,
    type: Envoy.Api.V2.Cluster.CommonLbConfig.ZoneAwareLbConfig,
    oneof: 0

  field :locality_weighted_lb_config, 3,
    type: Envoy.Api.V2.Cluster.CommonLbConfig.LocalityWeightedLbConfig,
    oneof: 0

  field :update_merge_window, 4, type: Google.Protobuf.Duration
end

defmodule Envoy.Api.V2.Cluster.CommonLbConfig.ZoneAwareLbConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          routing_enabled: Envoy.Type.Percent.t() | nil,
          min_cluster_size: Google.Protobuf.UInt64Value.t() | nil
        }
  defstruct [:routing_enabled, :min_cluster_size]

  field :routing_enabled, 1, type: Envoy.Type.Percent
  field :min_cluster_size, 2, type: Google.Protobuf.UInt64Value
end

defmodule Envoy.Api.V2.Cluster.CommonLbConfig.LocalityWeightedLbConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []
end

defmodule Envoy.Api.V2.Cluster.DiscoveryType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :STATIC, 0
  field :STRICT_DNS, 1
  field :LOGICAL_DNS, 2
  field :EDS, 3
  field :ORIGINAL_DST, 4
end

defmodule Envoy.Api.V2.Cluster.LbPolicy do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :ROUND_ROBIN, 0
  field :LEAST_REQUEST, 1
  field :RING_HASH, 2
  field :RANDOM, 3
  field :ORIGINAL_DST_LB, 4
  field :MAGLEV, 5
end

defmodule Envoy.Api.V2.Cluster.DnsLookupFamily do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :AUTO, 0
  field :V4_ONLY, 1
  field :V6_ONLY, 2
end

defmodule Envoy.Api.V2.Cluster.ClusterProtocolSelection do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :USE_CONFIGURED_PROTOCOL, 0
  field :USE_DOWNSTREAM_PROTOCOL, 1
end

defmodule Envoy.Api.V2.UpstreamBindConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          source_address: Envoy.Api.V2.Core.Address.t() | nil
        }
  defstruct [:source_address]

  field :source_address, 1, type: Envoy.Api.V2.Core.Address
end

defmodule Envoy.Api.V2.UpstreamConnectionOptions do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          tcp_keepalive: Envoy.Api.V2.Core.TcpKeepalive.t() | nil
        }
  defstruct [:tcp_keepalive]

  field :tcp_keepalive, 1, type: Envoy.Api.V2.Core.TcpKeepalive
end

defmodule Envoy.Api.V2.ClusterDiscoveryService.Service do
  @moduledoc false
  use GRPC.Service, name: "envoy.api.v2.ClusterDiscoveryService"

  rpc :StreamClusters,
      stream(Envoy.Api.V2.DiscoveryRequest),
      stream(Envoy.Api.V2.DiscoveryResponse)

  rpc :IncrementalClusters,
      stream(Envoy.Api.V2.IncrementalDiscoveryRequest),
      stream(Envoy.Api.V2.IncrementalDiscoveryResponse)

  rpc :FetchClusters, Envoy.Api.V2.DiscoveryRequest, Envoy.Api.V2.DiscoveryResponse
end

defmodule Envoy.Api.V2.ClusterDiscoveryService.Stub do
  @moduledoc false
  use GRPC.Stub, service: Envoy.Api.V2.ClusterDiscoveryService.Service
end
