defmodule Envoy.Config.Accesslog.V2.TcpGrpcAccessLogConfig do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    common_config: Envoy.Config.Accesslog.V2.CommonGrpcAccessLogConfig.t
  }
  defstruct [:common_config]

  field :common_config, 1, type: Envoy.Config.Accesslog.V2.CommonGrpcAccessLogConfig
end

defmodule Envoy.Config.Accesslog.V2.HttpGrpcAccessLogConfig do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    common_config:                      Envoy.Config.Accesslog.V2.CommonGrpcAccessLogConfig.t,
    additional_request_headers_to_log:  [String.t],
    additional_response_headers_to_log: [String.t]
  }
  defstruct [:common_config, :additional_request_headers_to_log, :additional_response_headers_to_log]

  field :common_config, 1, type: Envoy.Config.Accesslog.V2.CommonGrpcAccessLogConfig
  field :additional_request_headers_to_log, 2, repeated: true, type: :string
  field :additional_response_headers_to_log, 3, repeated: true, type: :string
end

defmodule Envoy.Config.Accesslog.V2.CommonGrpcAccessLogConfig do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    log_name:     String.t,
    grpc_service: Envoy.Api.V2.Core.GrpcService.t
  }
  defstruct [:log_name, :grpc_service]

  field :log_name, 1, type: :string
  field :grpc_service, 2, type: Envoy.Api.V2.Core.GrpcService
end