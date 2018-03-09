defmodule Envoy.Config.Filter.Accesslog.V2.AccessLogCommon do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          sample_rate: float,
          downstream_remote_address: Envoy.Api.V2.Core.Address.t(),
          downstream_local_address: Envoy.Api.V2.Core.Address.t(),
          tls_properties: Envoy.Config.Filter.Accesslog.V2.TLSProperties.t(),
          start_time: Google.Protobuf.Timestamp.t(),
          time_to_last_rx_byte: Google.Protobuf.Duration.t(),
          time_to_first_upstream_tx_byte: Google.Protobuf.Duration.t(),
          time_to_last_upstream_tx_byte: Google.Protobuf.Duration.t(),
          time_to_first_upstream_rx_byte: Google.Protobuf.Duration.t(),
          time_to_last_upstream_rx_byte: Google.Protobuf.Duration.t(),
          time_to_first_downstream_tx_byte: Google.Protobuf.Duration.t(),
          time_to_last_downstream_tx_byte: Google.Protobuf.Duration.t(),
          upstream_remote_address: Envoy.Api.V2.Core.Address.t(),
          upstream_local_address: Envoy.Api.V2.Core.Address.t(),
          upstream_cluster: String.t(),
          response_flags: Envoy.Config.Filter.Accesslog.V2.ResponseFlags.t(),
          metadata: Envoy.Api.V2.Core.Metadata.t()
        }
  defstruct [
    :sample_rate,
    :downstream_remote_address,
    :downstream_local_address,
    :tls_properties,
    :start_time,
    :time_to_last_rx_byte,
    :time_to_first_upstream_tx_byte,
    :time_to_last_upstream_tx_byte,
    :time_to_first_upstream_rx_byte,
    :time_to_last_upstream_rx_byte,
    :time_to_first_downstream_tx_byte,
    :time_to_last_downstream_tx_byte,
    :upstream_remote_address,
    :upstream_local_address,
    :upstream_cluster,
    :response_flags,
    :metadata
  ]

  field :sample_rate, 1, type: :double
  field :downstream_remote_address, 2, type: Envoy.Api.V2.Core.Address
  field :downstream_local_address, 3, type: Envoy.Api.V2.Core.Address
  field :tls_properties, 4, type: Envoy.Config.Filter.Accesslog.V2.TLSProperties
  field :start_time, 5, type: Google.Protobuf.Timestamp
  field :time_to_last_rx_byte, 6, type: Google.Protobuf.Duration
  field :time_to_first_upstream_tx_byte, 7, type: Google.Protobuf.Duration
  field :time_to_last_upstream_tx_byte, 8, type: Google.Protobuf.Duration
  field :time_to_first_upstream_rx_byte, 9, type: Google.Protobuf.Duration
  field :time_to_last_upstream_rx_byte, 10, type: Google.Protobuf.Duration
  field :time_to_first_downstream_tx_byte, 11, type: Google.Protobuf.Duration
  field :time_to_last_downstream_tx_byte, 12, type: Google.Protobuf.Duration
  field :upstream_remote_address, 13, type: Envoy.Api.V2.Core.Address
  field :upstream_local_address, 14, type: Envoy.Api.V2.Core.Address
  field :upstream_cluster, 15, type: :string
  field :response_flags, 16, type: Envoy.Config.Filter.Accesslog.V2.ResponseFlags
  field :metadata, 17, type: Envoy.Api.V2.Core.Metadata
end

defmodule Envoy.Config.Filter.Accesslog.V2.ResponseFlags do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          failed_local_healthcheck: boolean,
          no_healthy_upstream: boolean,
          upstream_request_timeout: boolean,
          local_reset: boolean,
          upstream_remote_reset: boolean,
          upstream_connection_failure: boolean,
          upstream_connection_termination: boolean,
          upstream_overflow: boolean,
          no_route_found: boolean,
          delay_injected: boolean,
          fault_injected: boolean,
          rate_limited: boolean,
          unauthorized_details: Envoy.Config.Filter.Accesslog.V2.ResponseFlags.Unauthorized.t()
        }
  defstruct [
    :failed_local_healthcheck,
    :no_healthy_upstream,
    :upstream_request_timeout,
    :local_reset,
    :upstream_remote_reset,
    :upstream_connection_failure,
    :upstream_connection_termination,
    :upstream_overflow,
    :no_route_found,
    :delay_injected,
    :fault_injected,
    :rate_limited,
    :unauthorized_details
  ]

  field :failed_local_healthcheck, 1, type: :bool
  field :no_healthy_upstream, 2, type: :bool
  field :upstream_request_timeout, 3, type: :bool
  field :local_reset, 4, type: :bool
  field :upstream_remote_reset, 5, type: :bool
  field :upstream_connection_failure, 6, type: :bool
  field :upstream_connection_termination, 7, type: :bool
  field :upstream_overflow, 8, type: :bool
  field :no_route_found, 9, type: :bool
  field :delay_injected, 10, type: :bool
  field :fault_injected, 11, type: :bool
  field :rate_limited, 12, type: :bool

  field :unauthorized_details, 13,
    type: Envoy.Config.Filter.Accesslog.V2.ResponseFlags.Unauthorized
end

defmodule Envoy.Config.Filter.Accesslog.V2.ResponseFlags.Unauthorized do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          reason: integer
        }
  defstruct [:reason]

  field :reason, 1,
    type: Envoy.Config.Filter.Accesslog.V2.ResponseFlags.Unauthorized.Reason,
    enum: true
end

defmodule Envoy.Config.Filter.Accesslog.V2.ResponseFlags.Unauthorized.Reason do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :REASON_UNSPECIFIED, 0
  field :EXTERNAL_SERVICE, 1
end

defmodule Envoy.Config.Filter.Accesslog.V2.TLSProperties do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          tls_version: integer,
          tls_cipher_suite: Google.Protobuf.UInt32Value.t(),
          tls_sni_hostname: String.t()
        }
  defstruct [:tls_version, :tls_cipher_suite, :tls_sni_hostname]

  field :tls_version, 1,
    type: Envoy.Config.Filter.Accesslog.V2.TLSProperties.TLSVersion,
    enum: true

  field :tls_cipher_suite, 2, type: Google.Protobuf.UInt32Value
  field :tls_sni_hostname, 3, type: :string
end

defmodule Envoy.Config.Filter.Accesslog.V2.TLSProperties.TLSVersion do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :VERSION_UNSPECIFIED, 0
  field :TLSv1, 1
  field :TLSv1_1, 2
  field :TLSv1_2, 3
  field :TLSv1_3, 4
end

defmodule Envoy.Config.Filter.Accesslog.V2.TCPAccessLogEntry do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          common_properties: Envoy.Config.Filter.Accesslog.V2.AccessLogCommon.t()
        }
  defstruct [:common_properties]

  field :common_properties, 1, type: Envoy.Config.Filter.Accesslog.V2.AccessLogCommon
end

defmodule Envoy.Config.Filter.Accesslog.V2.HTTPRequestProperties do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          request_method: integer,
          scheme: String.t(),
          authority: String.t(),
          port: Google.Protobuf.UInt32Value.t(),
          path: String.t(),
          user_agent: String.t(),
          referer: String.t(),
          forwarded_for: String.t(),
          request_id: String.t(),
          original_path: String.t(),
          request_headers_bytes: non_neg_integer,
          request_body_bytes: non_neg_integer,
          request_headers: %{String.t() => String.t()}
        }
  defstruct [
    :request_method,
    :scheme,
    :authority,
    :port,
    :path,
    :user_agent,
    :referer,
    :forwarded_for,
    :request_id,
    :original_path,
    :request_headers_bytes,
    :request_body_bytes,
    :request_headers
  ]

  field :request_method, 1, type: Envoy.Api.V2.Core.RequestMethod, enum: true
  field :scheme, 2, type: :string
  field :authority, 3, type: :string
  field :port, 4, type: Google.Protobuf.UInt32Value
  field :path, 5, type: :string
  field :user_agent, 6, type: :string
  field :referer, 7, type: :string
  field :forwarded_for, 8, type: :string
  field :request_id, 9, type: :string
  field :original_path, 10, type: :string
  field :request_headers_bytes, 11, type: :uint64
  field :request_body_bytes, 12, type: :uint64

  field :request_headers, 13,
    repeated: true,
    type: Envoy.Config.Filter.Accesslog.V2.HTTPRequestProperties.RequestHeadersEntry,
    map: true
end

defmodule Envoy.Config.Filter.Accesslog.V2.HTTPRequestProperties.RequestHeadersEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Envoy.Config.Filter.Accesslog.V2.HTTPResponseProperties do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          response_code: Google.Protobuf.UInt32Value.t(),
          response_headers_bytes: non_neg_integer,
          response_body_bytes: non_neg_integer,
          response_headers: %{String.t() => String.t()}
        }
  defstruct [:response_code, :response_headers_bytes, :response_body_bytes, :response_headers]

  field :response_code, 1, type: Google.Protobuf.UInt32Value
  field :response_headers_bytes, 2, type: :uint64
  field :response_body_bytes, 3, type: :uint64

  field :response_headers, 4,
    repeated: true,
    type: Envoy.Config.Filter.Accesslog.V2.HTTPResponseProperties.ResponseHeadersEntry,
    map: true
end

defmodule Envoy.Config.Filter.Accesslog.V2.HTTPResponseProperties.ResponseHeadersEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Envoy.Config.Filter.Accesslog.V2.HTTPAccessLogEntry do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          common_properties: Envoy.Config.Filter.Accesslog.V2.AccessLogCommon.t(),
          protocol_version: integer,
          request: Envoy.Config.Filter.Accesslog.V2.HTTPRequestProperties.t(),
          response: Envoy.Config.Filter.Accesslog.V2.HTTPResponseProperties.t()
        }
  defstruct [:common_properties, :protocol_version, :request, :response]

  field :common_properties, 1, type: Envoy.Config.Filter.Accesslog.V2.AccessLogCommon

  field :protocol_version, 2,
    type: Envoy.Config.Filter.Accesslog.V2.HTTPAccessLogEntry.HTTPVersion,
    enum: true

  field :request, 3, type: Envoy.Config.Filter.Accesslog.V2.HTTPRequestProperties
  field :response, 4, type: Envoy.Config.Filter.Accesslog.V2.HTTPResponseProperties
end

defmodule Envoy.Config.Filter.Accesslog.V2.HTTPAccessLogEntry.HTTPVersion do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :PROTOCOL_UNSPECIFIED, 0
  field :HTTP10, 1
  field :HTTP11, 2
  field :HTTP2, 3
end

defmodule Envoy.Config.Filter.Accesslog.V2.AccessLog do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          filter: Envoy.Config.Filter.Accesslog.V2.AccessLogFilter.t(),
          config: Google.Protobuf.Struct.t()
        }
  defstruct [:name, :filter, :config]

  field :name, 1, type: :string
  field :filter, 2, type: Envoy.Config.Filter.Accesslog.V2.AccessLogFilter
  field :config, 3, type: Google.Protobuf.Struct
end

defmodule Envoy.Config.Filter.Accesslog.V2.AccessLogFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filter_specifier: {atom, any}
        }
  defstruct [:filter_specifier]

  oneof :filter_specifier, 0
  field :status_code_filter, 1, type: Envoy.Config.Filter.Accesslog.V2.StatusCodeFilter, oneof: 0
  field :duration_filter, 2, type: Envoy.Config.Filter.Accesslog.V2.DurationFilter, oneof: 0

  field :not_health_check_filter, 3,
    type: Envoy.Config.Filter.Accesslog.V2.NotHealthCheckFilter,
    oneof: 0

  field :traceable_filter, 4, type: Envoy.Config.Filter.Accesslog.V2.TraceableFilter, oneof: 0
  field :runtime_filter, 5, type: Envoy.Config.Filter.Accesslog.V2.RuntimeFilter, oneof: 0
  field :and_filter, 6, type: Envoy.Config.Filter.Accesslog.V2.AndFilter, oneof: 0
  field :or_filter, 7, type: Envoy.Config.Filter.Accesslog.V2.OrFilter, oneof: 0
end

defmodule Envoy.Config.Filter.Accesslog.V2.ComparisonFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          op: integer,
          value: Envoy.Api.V2.Core.RuntimeUInt32.t()
        }
  defstruct [:op, :value]

  field :op, 1, type: Envoy.Config.Filter.Accesslog.V2.ComparisonFilter.Op, enum: true
  field :value, 2, type: Envoy.Api.V2.Core.RuntimeUInt32
end

defmodule Envoy.Config.Filter.Accesslog.V2.ComparisonFilter.Op do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :EQ, 0
  field :GE, 1
  field :LE, 2
end

defmodule Envoy.Config.Filter.Accesslog.V2.StatusCodeFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          comparison: Envoy.Config.Filter.Accesslog.V2.ComparisonFilter.t()
        }
  defstruct [:comparison]

  field :comparison, 1, type: Envoy.Config.Filter.Accesslog.V2.ComparisonFilter
end

defmodule Envoy.Config.Filter.Accesslog.V2.DurationFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          comparison: Envoy.Config.Filter.Accesslog.V2.ComparisonFilter.t()
        }
  defstruct [:comparison]

  field :comparison, 1, type: Envoy.Config.Filter.Accesslog.V2.ComparisonFilter
end

defmodule Envoy.Config.Filter.Accesslog.V2.NotHealthCheckFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule Envoy.Config.Filter.Accesslog.V2.TraceableFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule Envoy.Config.Filter.Accesslog.V2.RuntimeFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          runtime_key: String.t(),
          percent_sampled: Envoy.Type.FractionalPercent.t(),
          use_independent_randomness: boolean
        }
  defstruct [:runtime_key, :percent_sampled, :use_independent_randomness]

  field :runtime_key, 1, type: :string
  field :percent_sampled, 2, type: Envoy.Type.FractionalPercent
  field :use_independent_randomness, 3, type: :bool
end

defmodule Envoy.Config.Filter.Accesslog.V2.AndFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filters: [Envoy.Config.Filter.Accesslog.V2.AccessLogFilter.t()]
        }
  defstruct [:filters]

  field :filters, 1, repeated: true, type: Envoy.Config.Filter.Accesslog.V2.AccessLogFilter
end

defmodule Envoy.Config.Filter.Accesslog.V2.OrFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filters: [Envoy.Config.Filter.Accesslog.V2.AccessLogFilter.t()]
        }
  defstruct [:filters]

  field :filters, 2, repeated: true, type: Envoy.Config.Filter.Accesslog.V2.AccessLogFilter
end

defmodule Envoy.Config.Filter.Accesslog.V2.FileAccessLog do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          path: String.t(),
          format: String.t()
        }
  defstruct [:path, :format]

  field :path, 1, type: :string
  field :format, 2, type: :string
end
