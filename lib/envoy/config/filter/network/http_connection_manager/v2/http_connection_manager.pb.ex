defmodule Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    route_specifier:                                   {atom, any},
    codec_type:                                        integer,
    stat_prefix:                                       String.t,
    http_filters:                                      [Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpFilter.t],
    add_user_agent:                                    Google.Protobuf.BoolValue.t,
    tracing:                                           Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.Tracing.t,
    http_protocol_options:                             Envoy.Api.V2.Core.Http1ProtocolOptions.t,
    http2_protocol_options:                            Envoy.Api.V2.Core.Http2ProtocolOptions.t,
    server_name:                                       String.t,
    idle_timeout:                                      Google.Protobuf.Duration.t,
    drain_timeout:                                     Google.Protobuf.Duration.t,
    access_log:                                        [Envoy.Config.Filter.Accesslog.V2.AccessLog.t],
    use_remote_address:                                Google.Protobuf.BoolValue.t,
    xff_num_trusted_hops:                              non_neg_integer,
    generate_request_id:                               Google.Protobuf.BoolValue.t,
    forward_client_cert_details:                       integer,
    set_current_client_cert_details:                   Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.SetCurrentClientCertDetails.t,
    proxy_100_continue:                                boolean,
    represent_ipv4_remote_address_as_ipv4_mapped_ipv6: boolean
  }
  defstruct [:route_specifier, :codec_type, :stat_prefix, :http_filters, :add_user_agent, :tracing, :http_protocol_options, :http2_protocol_options, :server_name, :idle_timeout, :drain_timeout, :access_log, :use_remote_address, :xff_num_trusted_hops, :generate_request_id, :forward_client_cert_details, :set_current_client_cert_details, :proxy_100_continue, :represent_ipv4_remote_address_as_ipv4_mapped_ipv6]

  oneof :route_specifier, 0
  field :codec_type, 1, type: Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.CodecType, enum: true
  field :stat_prefix, 2, type: :string
  field :rds, 3, type: Envoy.Config.Filter.Network.HttpConnectionManager.V2.Rds, oneof: 0
  field :route_config, 4, type: Envoy.Api.V2.RouteConfiguration, oneof: 0
  field :http_filters, 5, repeated: true, type: Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpFilter
  field :add_user_agent, 6, type: Google.Protobuf.BoolValue
  field :tracing, 7, type: Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.Tracing
  field :http_protocol_options, 8, type: Envoy.Api.V2.Core.Http1ProtocolOptions
  field :http2_protocol_options, 9, type: Envoy.Api.V2.Core.Http2ProtocolOptions
  field :server_name, 10, type: :string
  field :idle_timeout, 11, type: Google.Protobuf.Duration
  field :drain_timeout, 12, type: Google.Protobuf.Duration
  field :access_log, 13, repeated: true, type: Envoy.Config.Filter.Accesslog.V2.AccessLog
  field :use_remote_address, 14, type: Google.Protobuf.BoolValue
  field :xff_num_trusted_hops, 19, type: :uint32
  field :generate_request_id, 15, type: Google.Protobuf.BoolValue
  field :forward_client_cert_details, 16, type: Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.ForwardClientCertDetails, enum: true
  field :set_current_client_cert_details, 17, type: Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.SetCurrentClientCertDetails
  field :proxy_100_continue, 18, type: :bool
  field :represent_ipv4_remote_address_as_ipv4_mapped_ipv6, 20, type: :bool
end

defmodule Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.Tracing do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    operation_name:           integer,
    request_headers_for_tags: [String.t],
    client_sampling:          Envoy.Api.V2.Core.Percent.t,
    random_sampling:          Envoy.Api.V2.Core.Percent.t,
    overall_sampling:         Envoy.Api.V2.Core.Percent.t
  }
  defstruct [:operation_name, :request_headers_for_tags, :client_sampling, :random_sampling, :overall_sampling]

  field :operation_name, 1, type: Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.Tracing.OperationName, enum: true
  field :request_headers_for_tags, 2, repeated: true, type: :string
  field :client_sampling, 3, type: Envoy.Api.V2.Core.Percent
  field :random_sampling, 4, type: Envoy.Api.V2.Core.Percent
  field :overall_sampling, 5, type: Envoy.Api.V2.Core.Percent
end

defmodule Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.Tracing.OperationName do
  use Protobuf, enum: true, syntax: :proto3

  field :INGRESS, 0
  field :EGRESS, 1
end

defmodule Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.SetCurrentClientCertDetails do
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

defmodule Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.CodecType do
  use Protobuf, enum: true, syntax: :proto3

  field :AUTO, 0
  field :HTTP1, 1
  field :HTTP2, 2
end

defmodule Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpConnectionManager.ForwardClientCertDetails do
  use Protobuf, enum: true, syntax: :proto3

  field :SANITIZE, 0
  field :FORWARD_ONLY, 1
  field :APPEND_FORWARD, 2
  field :SANITIZE_SET, 3
  field :ALWAYS_FORWARD_ONLY, 4
end

defmodule Envoy.Config.Filter.Network.HttpConnectionManager.V2.Rds do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    config_source:     Envoy.Api.V2.Core.ConfigSource.t,
    route_config_name: String.t
  }
  defstruct [:config_source, :route_config_name]

  field :config_source, 1, type: Envoy.Api.V2.Core.ConfigSource
  field :route_config_name, 2, type: :string
end

defmodule Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpFilter do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    name:          String.t,
    config:        Google.Protobuf.Struct.t,
    deprecated_v1: Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpFilter.DeprecatedV1.t
  }
  defstruct [:name, :config, :deprecated_v1]

  field :name, 1, type: :string
  field :config, 2, type: Google.Protobuf.Struct
  field :deprecated_v1, 3, type: Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpFilter.DeprecatedV1, deprecated: true
end

defmodule Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpFilter.DeprecatedV1 do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    type: String.t
  }
  defstruct [:type]

  field :type, 1, type: :string
end
