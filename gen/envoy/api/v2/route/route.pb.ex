defmodule Envoy.Api.V2.Route.VirtualHost do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          domains: [String.t()],
          routes: [Envoy.Api.V2.Route.Route.t()],
          require_tls: integer,
          virtual_clusters: [Envoy.Api.V2.Route.VirtualCluster.t()],
          rate_limits: [Envoy.Api.V2.Route.RateLimit.t()],
          request_headers_to_add: [Envoy.Api.V2.Core.HeaderValueOption.t()],
          response_headers_to_add: [Envoy.Api.V2.Core.HeaderValueOption.t()],
          response_headers_to_remove: [String.t()],
          cors: Envoy.Api.V2.Route.CorsPolicy.t(),
          auth: Envoy.Api.V2.Auth.AuthAction.t()
        }
  defstruct [
    :name,
    :domains,
    :routes,
    :require_tls,
    :virtual_clusters,
    :rate_limits,
    :request_headers_to_add,
    :response_headers_to_add,
    :response_headers_to_remove,
    :cors,
    :auth
  ]

  field :name, 1, type: :string
  field :domains, 2, repeated: true, type: :string
  field :routes, 3, repeated: true, type: Envoy.Api.V2.Route.Route
  field :require_tls, 4, type: Envoy.Api.V2.Route.VirtualHost.TlsRequirementType, enum: true
  field :virtual_clusters, 5, repeated: true, type: Envoy.Api.V2.Route.VirtualCluster
  field :rate_limits, 6, repeated: true, type: Envoy.Api.V2.Route.RateLimit
  field :request_headers_to_add, 7, repeated: true, type: Envoy.Api.V2.Core.HeaderValueOption
  field :response_headers_to_add, 10, repeated: true, type: Envoy.Api.V2.Core.HeaderValueOption
  field :response_headers_to_remove, 11, repeated: true, type: :string
  field :cors, 8, type: Envoy.Api.V2.Route.CorsPolicy
  field :auth, 9, type: Envoy.Api.V2.Auth.AuthAction
end

defmodule Envoy.Api.V2.Route.VirtualHost.TlsRequirementType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :NONE, 0
  field :EXTERNAL_ONLY, 1
  field :ALL, 2
end

defmodule Envoy.Api.V2.Route.Route do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          action: {atom, any},
          match: Envoy.Api.V2.Route.RouteMatch.t(),
          metadata: Envoy.Api.V2.Core.Metadata.t(),
          decorator: Envoy.Api.V2.Route.Decorator.t(),
          auth: Envoy.Api.V2.Auth.AuthAction.t()
        }
  defstruct [:action, :match, :metadata, :decorator, :auth]

  oneof :action, 0
  field :match, 1, type: Envoy.Api.V2.Route.RouteMatch
  field :route, 2, type: Envoy.Api.V2.Route.RouteAction, oneof: 0
  field :redirect, 3, type: Envoy.Api.V2.Route.RedirectAction, oneof: 0
  field :direct_response, 7, type: Envoy.Api.V2.Route.DirectResponseAction, oneof: 0
  field :metadata, 4, type: Envoy.Api.V2.Core.Metadata
  field :decorator, 5, type: Envoy.Api.V2.Route.Decorator
  field :auth, 6, type: Envoy.Api.V2.Auth.AuthAction
end

defmodule Envoy.Api.V2.Route.WeightedCluster do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          clusters: [Envoy.Api.V2.Route.WeightedCluster.ClusterWeight.t()],
          total_weight: Google.Protobuf.UInt32Value.t(),
          runtime_key_prefix: String.t()
        }
  defstruct [:clusters, :total_weight, :runtime_key_prefix]

  field :clusters, 1, repeated: true, type: Envoy.Api.V2.Route.WeightedCluster.ClusterWeight
  field :total_weight, 3, type: Google.Protobuf.UInt32Value
  field :runtime_key_prefix, 2, type: :string
end

defmodule Envoy.Api.V2.Route.WeightedCluster.ClusterWeight do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          weight: Google.Protobuf.UInt32Value.t(),
          metadata_match: Envoy.Api.V2.Core.Metadata.t(),
          request_headers_to_add: [Envoy.Api.V2.Core.HeaderValueOption.t()],
          response_headers_to_add: [Envoy.Api.V2.Core.HeaderValueOption.t()],
          response_headers_to_remove: [String.t()]
        }
  defstruct [
    :name,
    :weight,
    :metadata_match,
    :request_headers_to_add,
    :response_headers_to_add,
    :response_headers_to_remove
  ]

  field :name, 1, type: :string
  field :weight, 2, type: Google.Protobuf.UInt32Value
  field :metadata_match, 3, type: Envoy.Api.V2.Core.Metadata
  field :request_headers_to_add, 4, repeated: true, type: Envoy.Api.V2.Core.HeaderValueOption
  field :response_headers_to_add, 5, repeated: true, type: Envoy.Api.V2.Core.HeaderValueOption
  field :response_headers_to_remove, 6, repeated: true, type: :string
end

defmodule Envoy.Api.V2.Route.RouteMatch do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          path_specifier: {atom, any},
          case_sensitive: Google.Protobuf.BoolValue.t(),
          runtime: Envoy.Api.V2.Core.RuntimeUInt32.t(),
          headers: [Envoy.Api.V2.Route.HeaderMatcher.t()],
          query_parameters: [Envoy.Api.V2.Route.QueryParameterMatcher.t()]
        }
  defstruct [:path_specifier, :case_sensitive, :runtime, :headers, :query_parameters]

  oneof :path_specifier, 0
  field :prefix, 1, type: :string, oneof: 0
  field :path, 2, type: :string, oneof: 0
  field :regex, 3, type: :string, oneof: 0
  field :case_sensitive, 4, type: Google.Protobuf.BoolValue
  field :runtime, 5, type: Envoy.Api.V2.Core.RuntimeUInt32
  field :headers, 6, repeated: true, type: Envoy.Api.V2.Route.HeaderMatcher
  field :query_parameters, 7, repeated: true, type: Envoy.Api.V2.Route.QueryParameterMatcher
end

defmodule Envoy.Api.V2.Route.CorsPolicy do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          allow_origin: [String.t()],
          allow_methods: String.t(),
          allow_headers: String.t(),
          expose_headers: String.t(),
          max_age: String.t(),
          allow_credentials: Google.Protobuf.BoolValue.t(),
          enabled: Google.Protobuf.BoolValue.t()
        }
  defstruct [
    :allow_origin,
    :allow_methods,
    :allow_headers,
    :expose_headers,
    :max_age,
    :allow_credentials,
    :enabled
  ]

  field :allow_origin, 1, repeated: true, type: :string
  field :allow_methods, 2, type: :string
  field :allow_headers, 3, type: :string
  field :expose_headers, 4, type: :string
  field :max_age, 5, type: :string
  field :allow_credentials, 6, type: Google.Protobuf.BoolValue
  field :enabled, 7, type: Google.Protobuf.BoolValue
end

defmodule Envoy.Api.V2.Route.RouteAction do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          cluster_specifier: {atom, any},
          host_rewrite_specifier: {atom, any},
          cluster_not_found_response_code: integer,
          metadata_match: Envoy.Api.V2.Core.Metadata.t(),
          prefix_rewrite: String.t(),
          timeout: Google.Protobuf.Duration.t(),
          retry_policy: Envoy.Api.V2.Route.RouteAction.RetryPolicy.t(),
          request_mirror_policy: Envoy.Api.V2.Route.RouteAction.RequestMirrorPolicy.t(),
          priority: integer,
          request_headers_to_add: [Envoy.Api.V2.Core.HeaderValueOption.t()],
          response_headers_to_add: [Envoy.Api.V2.Core.HeaderValueOption.t()],
          response_headers_to_remove: [String.t()],
          rate_limits: [Envoy.Api.V2.Route.RateLimit.t()],
          include_vh_rate_limits: Google.Protobuf.BoolValue.t(),
          hash_policy: [Envoy.Api.V2.Route.RouteAction.HashPolicy.t()],
          use_websocket: Google.Protobuf.BoolValue.t(),
          cors: Envoy.Api.V2.Route.CorsPolicy.t()
        }
  defstruct [
    :cluster_specifier,
    :host_rewrite_specifier,
    :cluster_not_found_response_code,
    :metadata_match,
    :prefix_rewrite,
    :timeout,
    :retry_policy,
    :request_mirror_policy,
    :priority,
    :request_headers_to_add,
    :response_headers_to_add,
    :response_headers_to_remove,
    :rate_limits,
    :include_vh_rate_limits,
    :hash_policy,
    :use_websocket,
    :cors
  ]

  oneof :cluster_specifier, 0
  oneof :host_rewrite_specifier, 1
  field :cluster, 1, type: :string, oneof: 0
  field :cluster_header, 2, type: :string, oneof: 0
  field :weighted_clusters, 3, type: Envoy.Api.V2.Route.WeightedCluster, oneof: 0

  field :cluster_not_found_response_code, 20,
    type: Envoy.Api.V2.Route.RouteAction.ClusterNotFoundResponseCode,
    enum: true

  field :metadata_match, 4, type: Envoy.Api.V2.Core.Metadata
  field :prefix_rewrite, 5, type: :string
  field :host_rewrite, 6, type: :string, oneof: 1
  field :auto_host_rewrite, 7, type: Google.Protobuf.BoolValue, oneof: 1
  field :timeout, 8, type: Google.Protobuf.Duration
  field :retry_policy, 9, type: Envoy.Api.V2.Route.RouteAction.RetryPolicy
  field :request_mirror_policy, 10, type: Envoy.Api.V2.Route.RouteAction.RequestMirrorPolicy
  field :priority, 11, type: Envoy.Api.V2.Core.RoutingPriority, enum: true
  field :request_headers_to_add, 12, repeated: true, type: Envoy.Api.V2.Core.HeaderValueOption
  field :response_headers_to_add, 18, repeated: true, type: Envoy.Api.V2.Core.HeaderValueOption
  field :response_headers_to_remove, 19, repeated: true, type: :string
  field :rate_limits, 13, repeated: true, type: Envoy.Api.V2.Route.RateLimit
  field :include_vh_rate_limits, 14, type: Google.Protobuf.BoolValue
  field :hash_policy, 15, repeated: true, type: Envoy.Api.V2.Route.RouteAction.HashPolicy
  field :use_websocket, 16, type: Google.Protobuf.BoolValue
  field :cors, 17, type: Envoy.Api.V2.Route.CorsPolicy
end

defmodule Envoy.Api.V2.Route.RouteAction.RetryPolicy do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          retry_on: String.t(),
          num_retries: Google.Protobuf.UInt32Value.t(),
          per_try_timeout: Google.Protobuf.Duration.t()
        }
  defstruct [:retry_on, :num_retries, :per_try_timeout]

  field :retry_on, 1, type: :string
  field :num_retries, 2, type: Google.Protobuf.UInt32Value
  field :per_try_timeout, 3, type: Google.Protobuf.Duration
end

defmodule Envoy.Api.V2.Route.RouteAction.RequestMirrorPolicy do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          cluster: String.t(),
          runtime_key: String.t()
        }
  defstruct [:cluster, :runtime_key]

  field :cluster, 1, type: :string
  field :runtime_key, 2, type: :string
end

defmodule Envoy.Api.V2.Route.RouteAction.HashPolicy do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          policy_specifier: {atom, any}
        }
  defstruct [:policy_specifier]

  oneof :policy_specifier, 0
  field :header, 1, type: Envoy.Api.V2.Route.RouteAction.HashPolicy.Header, oneof: 0
  field :cookie, 2, type: Envoy.Api.V2.Route.RouteAction.HashPolicy.Cookie, oneof: 0

  field :connection_properties, 3,
    type: Envoy.Api.V2.Route.RouteAction.HashPolicy.ConnectionProperties,
    oneof: 0
end

defmodule Envoy.Api.V2.Route.RouteAction.HashPolicy.Header do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          header_name: String.t()
        }
  defstruct [:header_name]

  field :header_name, 1, type: :string
end

defmodule Envoy.Api.V2.Route.RouteAction.HashPolicy.Cookie do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          ttl: Google.Protobuf.Duration.t()
        }
  defstruct [:name, :ttl]

  field :name, 1, type: :string
  field :ttl, 2, type: Google.Protobuf.Duration
end

defmodule Envoy.Api.V2.Route.RouteAction.HashPolicy.ConnectionProperties do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          source_ip: boolean
        }
  defstruct [:source_ip]

  field :source_ip, 1, type: :bool
end

defmodule Envoy.Api.V2.Route.RouteAction.ClusterNotFoundResponseCode do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :SERVICE_UNAVAILABLE, 0
  field :NOT_FOUND, 1
end

defmodule Envoy.Api.V2.Route.RedirectAction do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          path_rewrite_specifier: {atom, any},
          host_redirect: String.t(),
          response_code: integer,
          https_redirect: boolean,
          strip_query: boolean
        }
  defstruct [
    :path_rewrite_specifier,
    :host_redirect,
    :response_code,
    :https_redirect,
    :strip_query
  ]

  oneof :path_rewrite_specifier, 0
  field :host_redirect, 1, type: :string
  field :path_redirect, 2, type: :string, oneof: 0
  field :prefix_rewrite, 5, type: :string, oneof: 0

  field :response_code, 3,
    type: Envoy.Api.V2.Route.RedirectAction.RedirectResponseCode,
    enum: true

  field :https_redirect, 4, type: :bool
  field :strip_query, 6, type: :bool
end

defmodule Envoy.Api.V2.Route.RedirectAction.RedirectResponseCode do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :MOVED_PERMANENTLY, 0
  field :FOUND, 1
  field :SEE_OTHER, 2
  field :TEMPORARY_REDIRECT, 3
  field :PERMANENT_REDIRECT, 4
end

defmodule Envoy.Api.V2.Route.DirectResponseAction do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          status: non_neg_integer,
          body: Envoy.Api.V2.Core.DataSource.t()
        }
  defstruct [:status, :body]

  field :status, 1, type: :uint32
  field :body, 2, type: Envoy.Api.V2.Core.DataSource
end

defmodule Envoy.Api.V2.Route.Decorator do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          operation: String.t()
        }
  defstruct [:operation]

  field :operation, 1, type: :string
end

defmodule Envoy.Api.V2.Route.VirtualCluster do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          pattern: String.t(),
          name: String.t(),
          method: integer
        }
  defstruct [:pattern, :name, :method]

  field :pattern, 1, type: :string
  field :name, 2, type: :string
  field :method, 3, type: Envoy.Api.V2.Core.RequestMethod, enum: true
end

defmodule Envoy.Api.V2.Route.RateLimit do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          stage: Google.Protobuf.UInt32Value.t(),
          disable_key: String.t(),
          actions: [Envoy.Api.V2.Route.RateLimit.Action.t()]
        }
  defstruct [:stage, :disable_key, :actions]

  field :stage, 1, type: Google.Protobuf.UInt32Value
  field :disable_key, 2, type: :string
  field :actions, 3, repeated: true, type: Envoy.Api.V2.Route.RateLimit.Action
end

defmodule Envoy.Api.V2.Route.RateLimit.Action do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          action_specifier: {atom, any}
        }
  defstruct [:action_specifier]

  oneof :action_specifier, 0
  field :source_cluster, 1, type: Envoy.Api.V2.Route.RateLimit.Action.SourceCluster, oneof: 0

  field :destination_cluster, 2,
    type: Envoy.Api.V2.Route.RateLimit.Action.DestinationCluster,
    oneof: 0

  field :request_headers, 3, type: Envoy.Api.V2.Route.RateLimit.Action.RequestHeaders, oneof: 0
  field :remote_address, 4, type: Envoy.Api.V2.Route.RateLimit.Action.RemoteAddress, oneof: 0
  field :generic_key, 5, type: Envoy.Api.V2.Route.RateLimit.Action.GenericKey, oneof: 0

  field :header_value_match, 6,
    type: Envoy.Api.V2.Route.RateLimit.Action.HeaderValueMatch,
    oneof: 0
end

defmodule Envoy.Api.V2.Route.RateLimit.Action.SourceCluster do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule Envoy.Api.V2.Route.RateLimit.Action.DestinationCluster do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule Envoy.Api.V2.Route.RateLimit.Action.RequestHeaders do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          header_name: String.t(),
          descriptor_key: String.t()
        }
  defstruct [:header_name, :descriptor_key]

  field :header_name, 1, type: :string
  field :descriptor_key, 2, type: :string
end

defmodule Envoy.Api.V2.Route.RateLimit.Action.RemoteAddress do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule Envoy.Api.V2.Route.RateLimit.Action.GenericKey do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          descriptor_value: String.t()
        }
  defstruct [:descriptor_value]

  field :descriptor_value, 1, type: :string
end

defmodule Envoy.Api.V2.Route.RateLimit.Action.HeaderValueMatch do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          descriptor_value: String.t(),
          expect_match: Google.Protobuf.BoolValue.t(),
          headers: [Envoy.Api.V2.Route.HeaderMatcher.t()]
        }
  defstruct [:descriptor_value, :expect_match, :headers]

  field :descriptor_value, 1, type: :string
  field :expect_match, 2, type: Google.Protobuf.BoolValue
  field :headers, 3, repeated: true, type: Envoy.Api.V2.Route.HeaderMatcher
end

defmodule Envoy.Api.V2.Route.HeaderMatcher do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          header_match_specifier: {atom, any},
          name: String.t(),
          value: String.t(),
          regex: Google.Protobuf.BoolValue.t()
        }
  defstruct [:header_match_specifier, :name, :value, :regex]

  oneof :header_match_specifier, 0
  field :name, 1, type: :string
  field :value, 2, type: :string
  field :regex, 3, type: Google.Protobuf.BoolValue
  field :exact_match, 4, type: :string, oneof: 0
  field :regex_match, 5, type: :string, oneof: 0
  field :range_match, 6, type: Envoy.Type.Int64Range, oneof: 0
end

defmodule Envoy.Api.V2.Route.QueryParameterMatcher do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          value: String.t(),
          regex: Google.Protobuf.BoolValue.t()
        }
  defstruct [:name, :value, :regex]

  field :name, 1, type: :string
  field :value, 3, type: :string
  field :regex, 4, type: Google.Protobuf.BoolValue
end
