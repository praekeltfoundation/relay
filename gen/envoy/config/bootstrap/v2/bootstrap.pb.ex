defmodule Envoy.Config.Bootstrap.V2.Bootstrap do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          node: Envoy.Api.V2.Core.Node.t() | nil,
          static_resources: Envoy.Config.Bootstrap.V2.Bootstrap.StaticResources.t() | nil,
          dynamic_resources: Envoy.Config.Bootstrap.V2.Bootstrap.DynamicResources.t() | nil,
          cluster_manager: Envoy.Config.Bootstrap.V2.ClusterManager.t() | nil,
          hds_config: Envoy.Api.V2.Core.ApiConfigSource.t() | nil,
          flags_path: String.t(),
          stats_sinks: [Envoy.Config.Metrics.V2.StatsSink.t()],
          stats_config: Envoy.Config.Metrics.V2.StatsConfig.t() | nil,
          stats_flush_interval: Google.Protobuf.Duration.t() | nil,
          watchdog: Envoy.Config.Bootstrap.V2.Watchdog.t() | nil,
          tracing: Envoy.Config.Trace.V2.Tracing.t() | nil,
          rate_limit_service: Envoy.Config.Ratelimit.V2.RateLimitServiceConfig.t() | nil,
          runtime: Envoy.Config.Bootstrap.V2.Runtime.t() | nil,
          admin: Envoy.Config.Bootstrap.V2.Admin.t() | nil,
          overload_manager: Envoy.Config.Overload.V2alpha.OverloadManager.t() | nil
        }
  defstruct [
    :node,
    :static_resources,
    :dynamic_resources,
    :cluster_manager,
    :hds_config,
    :flags_path,
    :stats_sinks,
    :stats_config,
    :stats_flush_interval,
    :watchdog,
    :tracing,
    :rate_limit_service,
    :runtime,
    :admin,
    :overload_manager
  ]

  field :node, 1, type: Envoy.Api.V2.Core.Node
  field :static_resources, 2, type: Envoy.Config.Bootstrap.V2.Bootstrap.StaticResources
  field :dynamic_resources, 3, type: Envoy.Config.Bootstrap.V2.Bootstrap.DynamicResources
  field :cluster_manager, 4, type: Envoy.Config.Bootstrap.V2.ClusterManager
  field :hds_config, 14, type: Envoy.Api.V2.Core.ApiConfigSource
  field :flags_path, 5, type: :string
  field :stats_sinks, 6, repeated: true, type: Envoy.Config.Metrics.V2.StatsSink
  field :stats_config, 13, type: Envoy.Config.Metrics.V2.StatsConfig
  field :stats_flush_interval, 7, type: Google.Protobuf.Duration
  field :watchdog, 8, type: Envoy.Config.Bootstrap.V2.Watchdog
  field :tracing, 9, type: Envoy.Config.Trace.V2.Tracing
  field :rate_limit_service, 10, type: Envoy.Config.Ratelimit.V2.RateLimitServiceConfig
  field :runtime, 11, type: Envoy.Config.Bootstrap.V2.Runtime
  field :admin, 12, type: Envoy.Config.Bootstrap.V2.Admin
  field :overload_manager, 15, type: Envoy.Config.Overload.V2alpha.OverloadManager
end

defmodule Envoy.Config.Bootstrap.V2.Bootstrap.StaticResources do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          listeners: [Envoy.Api.V2.Listener.t()],
          clusters: [Envoy.Api.V2.Cluster.t()],
          secrets: [Envoy.Api.V2.Auth.Secret.t()]
        }
  defstruct [:listeners, :clusters, :secrets]

  field :listeners, 1, repeated: true, type: Envoy.Api.V2.Listener
  field :clusters, 2, repeated: true, type: Envoy.Api.V2.Cluster
  field :secrets, 3, repeated: true, type: Envoy.Api.V2.Auth.Secret
end

defmodule Envoy.Config.Bootstrap.V2.Bootstrap.DynamicResources do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          lds_config: Envoy.Api.V2.Core.ConfigSource.t() | nil,
          cds_config: Envoy.Api.V2.Core.ConfigSource.t() | nil,
          ads_config: Envoy.Api.V2.Core.ApiConfigSource.t() | nil,
          deprecated_v1:
            Envoy.Config.Bootstrap.V2.Bootstrap.DynamicResources.DeprecatedV1.t() | nil
        }
  defstruct [:lds_config, :cds_config, :ads_config, :deprecated_v1]

  field :lds_config, 1, type: Envoy.Api.V2.Core.ConfigSource
  field :cds_config, 2, type: Envoy.Api.V2.Core.ConfigSource
  field :ads_config, 3, type: Envoy.Api.V2.Core.ApiConfigSource

  field :deprecated_v1, 4,
    type: Envoy.Config.Bootstrap.V2.Bootstrap.DynamicResources.DeprecatedV1,
    deprecated: true
end

defmodule Envoy.Config.Bootstrap.V2.Bootstrap.DynamicResources.DeprecatedV1 do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          sds_config: Envoy.Api.V2.Core.ConfigSource.t() | nil
        }
  defstruct [:sds_config]

  field :sds_config, 1, type: Envoy.Api.V2.Core.ConfigSource
end

defmodule Envoy.Config.Bootstrap.V2.Admin do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          access_log_path: String.t(),
          profile_path: String.t(),
          address: Envoy.Api.V2.Core.Address.t() | nil
        }
  defstruct [:access_log_path, :profile_path, :address]

  field :access_log_path, 1, type: :string
  field :profile_path, 2, type: :string
  field :address, 3, type: Envoy.Api.V2.Core.Address
end

defmodule Envoy.Config.Bootstrap.V2.ClusterManager do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          local_cluster_name: String.t(),
          outlier_detection: Envoy.Config.Bootstrap.V2.ClusterManager.OutlierDetection.t() | nil,
          upstream_bind_config: Envoy.Api.V2.Core.BindConfig.t() | nil,
          load_stats_config: Envoy.Api.V2.Core.ApiConfigSource.t() | nil
        }
  defstruct [:local_cluster_name, :outlier_detection, :upstream_bind_config, :load_stats_config]

  field :local_cluster_name, 1, type: :string
  field :outlier_detection, 2, type: Envoy.Config.Bootstrap.V2.ClusterManager.OutlierDetection
  field :upstream_bind_config, 3, type: Envoy.Api.V2.Core.BindConfig
  field :load_stats_config, 4, type: Envoy.Api.V2.Core.ApiConfigSource
end

defmodule Envoy.Config.Bootstrap.V2.ClusterManager.OutlierDetection do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          event_log_path: String.t()
        }
  defstruct [:event_log_path]

  field :event_log_path, 1, type: :string
end

defmodule Envoy.Config.Bootstrap.V2.Watchdog do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          miss_timeout: Google.Protobuf.Duration.t() | nil,
          megamiss_timeout: Google.Protobuf.Duration.t() | nil,
          kill_timeout: Google.Protobuf.Duration.t() | nil,
          multikill_timeout: Google.Protobuf.Duration.t() | nil
        }
  defstruct [:miss_timeout, :megamiss_timeout, :kill_timeout, :multikill_timeout]

  field :miss_timeout, 1, type: Google.Protobuf.Duration
  field :megamiss_timeout, 2, type: Google.Protobuf.Duration
  field :kill_timeout, 3, type: Google.Protobuf.Duration
  field :multikill_timeout, 4, type: Google.Protobuf.Duration
end

defmodule Envoy.Config.Bootstrap.V2.Runtime do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          symlink_root: String.t(),
          subdirectory: String.t(),
          override_subdirectory: String.t()
        }
  defstruct [:symlink_root, :subdirectory, :override_subdirectory]

  field :symlink_root, 1, type: :string
  field :subdirectory, 2, type: :string
  field :override_subdirectory, 3, type: :string
end
