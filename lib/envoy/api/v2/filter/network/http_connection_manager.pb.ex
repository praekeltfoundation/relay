defmodule Envoy.Api.V2.Filter.Network.HttpConnectionManager do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    route_specifier:                 {atom, any},
    codec_type:                      integer,
    stat_prefix:                     String.t,
    http_filters:                    [Envoy.Api.V2.Filter.Network.HttpFilter.t],
    add_user_agent:                  Google.Protobuf.BoolValue.t,
    tracing:                         Envoy.Api.V2.Filter.Network.HttpConnectionManager.Tracing.t,
    http_protocol_options:           Envoy.Api.V2.Http1ProtocolOptions.t,
    http2_protocol_options:          Envoy.Api.V2.Http2ProtocolOptions.t,
    server_name:                     String.t,
    idle_timeout:                    Google.Protobuf.Duration.t,
    drain_timeout:                   Google.Protobuf.Duration.t,
    access_log:                      [Envoy.Api.V2.Filter.Accesslog.AccessLog.t],
    use_remote_address:              Google.Protobuf.BoolValue.t,
    generate_request_id:             Google.Protobuf.BoolValue.t,
    forward_client_cert_details:     integer,
    set_current_client_cert_details: Envoy.Api.V2.Filter.Network.HttpConnectionManager.SetCurrentClientCertDetails.t,
    proxy_100_continue:              boolean
  }
  defstruct [:route_specifier, :codec_type, :stat_prefix, :http_filters, :add_user_agent, :tracing, :http_protocol_options, :http2_protocol_options, :server_name, :idle_timeout, :drain_timeout, :access_log, :use_remote_address, :generate_request_id, :forward_client_cert_details, :set_current_client_cert_details, :proxy_100_continue]

  oneof :route_specifier, 0
  field :codec_type, 1, type: Envoy.Api.V2.Filter.Network.HttpConnectionManager.CodecType, enum: true
  field :stat_prefix, 2, type: :string
  field :rds, 3, type: Envoy.Api.V2.Filter.Network.Rds, oneof: 0
  field :route_config, 4, type: Envoy.Api.V2.RouteConfiguration, oneof: 0
  field :http_filters, 5, repeated: true, type: Envoy.Api.V2.Filter.Network.HttpFilter
  field :add_user_agent, 6, type: Google.Protobuf.BoolValue
  field :tracing, 7, type: Envoy.Api.V2.Filter.Network.HttpConnectionManager.Tracing
  field :http_protocol_options, 8, type: Envoy.Api.V2.Http1ProtocolOptions
  field :http2_protocol_options, 9, type: Envoy.Api.V2.Http2ProtocolOptions
  field :server_name, 10, type: :string
  field :idle_timeout, 11, type: Google.Protobuf.Duration
  field :drain_timeout, 12, type: Google.Protobuf.Duration
  field :access_log, 13, repeated: true, type: Envoy.Api.V2.Filter.Accesslog.AccessLog
  field :use_remote_address, 14, type: Google.Protobuf.BoolValue
  field :generate_request_id, 15, type: Google.Protobuf.BoolValue
  field :forward_client_cert_details, 16, type: Envoy.Api.V2.Filter.Network.HttpConnectionManager.ForwardClientCertDetails, enum: true
  field :set_current_client_cert_details, 17, type: Envoy.Api.V2.Filter.Network.HttpConnectionManager.SetCurrentClientCertDetails
  field :proxy_100_continue, 18, type: :bool
end

defmodule Envoy.Api.V2.Filter.Network.HttpConnectionManager.Tracing do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    operation_name:           integer,
    request_headers_for_tags: [String.t],
    client_sampling:          Envoy.Api.V2.Percent.t,
    random_sampling:          Envoy.Api.V2.Percent.t,
    overall_sampling:         Envoy.Api.V2.Percent.t
  }
  defstruct [:operation_name, :request_headers_for_tags, :client_sampling, :random_sampling, :overall_sampling]

  field :operation_name, 1, type: Envoy.Api.V2.Filter.Network.HttpConnectionManager.Tracing.OperationName, enum: true
  field :request_headers_for_tags, 2, repeated: true, type: :string
  field :client_sampling, 3, type: Envoy.Api.V2.Percent
  field :random_sampling, 4, type: Envoy.Api.V2.Percent
  field :overall_sampling, 5, type: Envoy.Api.V2.Percent
end

defmodule Envoy.Api.V2.Filter.Network.HttpConnectionManager.Tracing.OperationName do
  use Protobuf, enum: true, syntax: :proto3

  field :INGRESS, 0
  field :EGRESS, 1
end

defmodule Envoy.Api.V2.Filter.Network.HttpConnectionManager.SetCurrentClientCertDetails do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    subject: Google.Protobuf.BoolValue.t,
    san:     Google.Protobuf.BoolValue.t,
    cert:    boolean
  }
  defstruct [:subject, :san, :cert]

  field :subject, 1, type: Google.Protobuf.BoolValue
  field :san, 2, type: Google.Protobuf.BoolValue
  field :cert, 3, type: :bool
end

defmodule Envoy.Api.V2.Filter.Network.HttpConnectionManager.CodecType do
  use Protobuf, enum: true, syntax: :proto3

  field :AUTO, 0
  field :HTTP1, 1
  field :HTTP2, 2
end

defmodule Envoy.Api.V2.Filter.Network.HttpConnectionManager.ForwardClientCertDetails do
  use Protobuf, enum: true, syntax: :proto3

  field :SANITIZE, 0
  field :FORWARD_ONLY, 1
  field :APPEND_FORWARD, 2
  field :SANITIZE_SET, 3
  field :ALWAYS_FORWARD_ONLY, 4
end

defmodule Envoy.Api.V2.Filter.Network.Rds do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    config_source:     Envoy.Api.V2.ConfigSource.t,
    route_config_name: String.t
  }
  defstruct [:config_source, :route_config_name]

  field :config_source, 1, type: Envoy.Api.V2.ConfigSource
  field :route_config_name, 2, type: :string
end

defmodule Envoy.Api.V2.Filter.Network.HttpFilter do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    name:          String.t,
    config:        Google.Protobuf.Struct.t,
    deprecated_v1: Envoy.Api.V2.Filter.Network.HttpFilter.DeprecatedV1.t
  }
  defstruct [:name, :config, :deprecated_v1]

  field :name, 1, type: :string
  field :config, 2, type: Google.Protobuf.Struct
  field :deprecated_v1, 3, type: Envoy.Api.V2.Filter.Network.HttpFilter.DeprecatedV1, deprecated: true
end

defmodule Envoy.Api.V2.Filter.Network.HttpFilter.DeprecatedV1 do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    type: String.t
  }
  defstruct [:type]

  field :type, 1, type: :string
end
