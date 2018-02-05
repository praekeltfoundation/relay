defmodule Envoy.Api.V2.Cluster do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    lb_config:                         {atom, any},
    name:                              String.t,
    type:                              integer,
    eds_cluster_config:                Envoy.Api.V2.Cluster.EdsClusterConfig.t,
    connect_timeout:                   Google.Protobuf.Duration.t,
    per_connection_buffer_limit_bytes: Google.Protobuf.UInt32Value.t,
    lb_policy:                         integer,
    hosts:                             [Envoy.Api.V2.Address.t],
    health_checks:                     [Envoy.Api.V2.HealthCheck.t],
    max_requests_per_connection:       Google.Protobuf.UInt32Value.t,
    circuit_breakers:                  Envoy.Api.V2.Cluster.CircuitBreakers.t,
    tls_context:                       Envoy.Api.V2.Auth.UpstreamTlsContext.t,
    http_protocol_options:             Envoy.Api.V2.Http1ProtocolOptions.t,
    http2_protocol_options:            Envoy.Api.V2.Http2ProtocolOptions.t,
    dns_refresh_rate:                  Google.Protobuf.Duration.t,
    dns_lookup_family:                 integer,
    dns_resolvers:                     [Envoy.Api.V2.Address.t],
    outlier_detection:                 Envoy.Api.V2.Cluster.OutlierDetection.t,
    cleanup_interval:                  Google.Protobuf.Duration.t,
    upstream_bind_config:              Envoy.Api.V2.BindConfig.t,
    lb_subset_config:                  Envoy.Api.V2.Cluster.LbSubsetConfig.t,
    transport_socket:                  Envoy.Api.V2.TransportSocket.t,
    metadata:                          Envoy.Api.V2.Metadata.t,
    protocol_selection:                integer
  }
  defstruct [:lb_config, :name, :type, :eds_cluster_config, :connect_timeout, :per_connection_buffer_limit_bytes, :lb_policy, :hosts, :health_checks, :max_requests_per_connection, :circuit_breakers, :tls_context, :http_protocol_options, :http2_protocol_options, :dns_refresh_rate, :dns_lookup_family, :dns_resolvers, :outlier_detection, :cleanup_interval, :upstream_bind_config, :lb_subset_config, :transport_socket, :metadata, :protocol_selection]

  oneof :lb_config, 0
  field :name, 1, type: :string
  field :type, 2, type: Envoy.Api.V2.Cluster.DiscoveryType, enum: true
  field :eds_cluster_config, 3, type: Envoy.Api.V2.Cluster.EdsClusterConfig
  field :connect_timeout, 4, type: Google.Protobuf.Duration
  field :per_connection_buffer_limit_bytes, 5, type: Google.Protobuf.UInt32Value
  field :lb_policy, 6, type: Envoy.Api.V2.Cluster.LbPolicy, enum: true
  field :hosts, 7, repeated: true, type: Envoy.Api.V2.Address
  field :health_checks, 8, repeated: true, type: Envoy.Api.V2.HealthCheck
  field :max_requests_per_connection, 9, type: Google.Protobuf.UInt32Value
  field :circuit_breakers, 10, type: Envoy.Api.V2.Cluster.CircuitBreakers
  field :tls_context, 11, type: Envoy.Api.V2.Auth.UpstreamTlsContext
  field :http_protocol_options, 13, type: Envoy.Api.V2.Http1ProtocolOptions
  field :http2_protocol_options, 14, type: Envoy.Api.V2.Http2ProtocolOptions
  field :dns_refresh_rate, 16, type: Google.Protobuf.Duration
  field :dns_lookup_family, 17, type: Envoy.Api.V2.Cluster.DnsLookupFamily, enum: true
  field :dns_resolvers, 18, repeated: true, type: Envoy.Api.V2.Address
  field :outlier_detection, 19, type: Envoy.Api.V2.Cluster.OutlierDetection
  field :cleanup_interval, 20, type: Google.Protobuf.Duration
  field :upstream_bind_config, 21, type: Envoy.Api.V2.BindConfig
  field :lb_subset_config, 22, type: Envoy.Api.V2.Cluster.LbSubsetConfig
  field :ring_hash_lb_config, 23, type: Envoy.Api.V2.Cluster.RingHashLbConfig, oneof: 0
  field :transport_socket, 24, type: Envoy.Api.V2.TransportSocket
  field :metadata, 25, type: Envoy.Api.V2.Metadata
  field :protocol_selection, 26, type: Envoy.Api.V2.Cluster.ClusterProtocolSelection, enum: true
end

defmodule Envoy.Api.V2.Cluster.EdsClusterConfig do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    eds_config:   Envoy.Api.V2.ConfigSource.t,
    service_name: String.t
  }
  defstruct [:eds_config, :service_name]

  field :eds_config, 1, type: Envoy.Api.V2.ConfigSource
  field :service_name, 2, type: :string
end

defmodule Envoy.Api.V2.Cluster.LbSubsetConfig do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    fallback_policy:  integer,
    default_subset:   Google.Protobuf.Struct.t,
    subset_selectors: [Envoy.Api.V2.Cluster.LbSubsetConfig.LbSubsetSelector.t]
  }
  defstruct [:fallback_policy, :default_subset, :subset_selectors]

  field :fallback_policy, 1, type: Envoy.Api.V2.Cluster.LbSubsetConfig.LbSubsetFallbackPolicy, enum: true
  field :default_subset, 2, type: Google.Protobuf.Struct
  field :subset_selectors, 3, repeated: true, type: Envoy.Api.V2.Cluster.LbSubsetConfig.LbSubsetSelector
end

defmodule Envoy.Api.V2.Cluster.LbSubsetConfig.LbSubsetSelector do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    keys: [String.t]
  }
  defstruct [:keys]

  field :keys, 1, repeated: true, type: :string
end

defmodule Envoy.Api.V2.Cluster.LbSubsetConfig.LbSubsetFallbackPolicy do
  use Protobuf, enum: true, syntax: :proto3

  field :NO_FALLBACK, 0
  field :ANY_ENDPOINT, 1
  field :DEFAULT_SUBSET, 2
end

defmodule Envoy.Api.V2.Cluster.RingHashLbConfig do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    minimum_ring_size: Google.Protobuf.UInt64Value.t,
    deprecated_v1:     Envoy.Api.V2.Cluster.RingHashLbConfig.DeprecatedV1.t
  }
  defstruct [:minimum_ring_size, :deprecated_v1]

  field :minimum_ring_size, 1, type: Google.Protobuf.UInt64Value
  field :deprecated_v1, 2, type: Envoy.Api.V2.Cluster.RingHashLbConfig.DeprecatedV1, deprecated: true
end

defmodule Envoy.Api.V2.Cluster.RingHashLbConfig.DeprecatedV1 do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    use_std_hash: Google.Protobuf.BoolValue.t
  }
  defstruct [:use_std_hash]

  field :use_std_hash, 1, type: Google.Protobuf.BoolValue
end

defmodule Envoy.Api.V2.Cluster.DiscoveryType do
  use Protobuf, enum: true, syntax: :proto3

  field :STATIC, 0
  field :STRICT_DNS, 1
  field :LOGICAL_DNS, 2
  field :EDS, 3
  field :ORIGINAL_DST, 4
end

defmodule Envoy.Api.V2.Cluster.LbPolicy do
  use Protobuf, enum: true, syntax: :proto3

  field :ROUND_ROBIN, 0
  field :LEAST_REQUEST, 1
  field :RING_HASH, 2
  field :RANDOM, 3
  field :ORIGINAL_DST_LB, 4
end

defmodule Envoy.Api.V2.Cluster.DnsLookupFamily do
  use Protobuf, enum: true, syntax: :proto3

  field :AUTO, 0
  field :V4_ONLY, 1
  field :V6_ONLY, 2
end

defmodule Envoy.Api.V2.Cluster.ClusterProtocolSelection do
  use Protobuf, enum: true, syntax: :proto3

  field :USE_CONFIGURED_PROTOCOL, 0
  field :USE_DOWNSTREAM_PROTOCOL, 1
end

defmodule Envoy.Api.V2.UpstreamBindConfig do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    source_address: Envoy.Api.V2.Address.t
  }
  defstruct [:source_address]

  field :source_address, 1, type: Envoy.Api.V2.Address
end

defmodule Envoy.Api.V2.ClusterDiscoveryService.Service do
  use GRPC.Service, name: "envoy.api.v2.ClusterDiscoveryService"

  rpc :StreamClusters, stream(Envoy.Api.V2.DiscoveryRequest), stream(Envoy.Api.V2.DiscoveryResponse)
  rpc :FetchClusters, Envoy.Api.V2.DiscoveryRequest, Envoy.Api.V2.DiscoveryResponse
end

defmodule Envoy.Api.V2.ClusterDiscoveryService.Stub do
  use GRPC.Stub, service: Envoy.Api.V2.ClusterDiscoveryService.Service
end
