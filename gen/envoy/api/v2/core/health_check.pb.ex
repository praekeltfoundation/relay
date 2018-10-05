defmodule Envoy.Api.V2.Core.HealthCheck do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          health_checker: {atom, any},
          timeout: Google.Protobuf.Duration.t(),
          interval: Google.Protobuf.Duration.t(),
          interval_jitter: Google.Protobuf.Duration.t(),
          interval_jitter_percent: non_neg_integer,
          unhealthy_threshold: Google.Protobuf.UInt32Value.t(),
          healthy_threshold: Google.Protobuf.UInt32Value.t(),
          alt_port: Google.Protobuf.UInt32Value.t(),
          reuse_connection: Google.Protobuf.BoolValue.t(),
          no_traffic_interval: Google.Protobuf.Duration.t(),
          unhealthy_interval: Google.Protobuf.Duration.t(),
          unhealthy_edge_interval: Google.Protobuf.Duration.t(),
          healthy_edge_interval: Google.Protobuf.Duration.t(),
          event_log_path: String.t()
        }
  defstruct [
    :health_checker,
    :timeout,
    :interval,
    :interval_jitter,
    :interval_jitter_percent,
    :unhealthy_threshold,
    :healthy_threshold,
    :alt_port,
    :reuse_connection,
    :no_traffic_interval,
    :unhealthy_interval,
    :unhealthy_edge_interval,
    :healthy_edge_interval,
    :event_log_path
  ]

  oneof :health_checker, 0
  field :timeout, 1, type: Google.Protobuf.Duration
  field :interval, 2, type: Google.Protobuf.Duration
  field :interval_jitter, 3, type: Google.Protobuf.Duration
  field :interval_jitter_percent, 18, type: :uint32
  field :unhealthy_threshold, 4, type: Google.Protobuf.UInt32Value
  field :healthy_threshold, 5, type: Google.Protobuf.UInt32Value
  field :alt_port, 6, type: Google.Protobuf.UInt32Value
  field :reuse_connection, 7, type: Google.Protobuf.BoolValue
  field :http_health_check, 8, type: Envoy.Api.V2.Core.HealthCheck.HttpHealthCheck, oneof: 0
  field :tcp_health_check, 9, type: Envoy.Api.V2.Core.HealthCheck.TcpHealthCheck, oneof: 0
  field :grpc_health_check, 11, type: Envoy.Api.V2.Core.HealthCheck.GrpcHealthCheck, oneof: 0
  field :custom_health_check, 13, type: Envoy.Api.V2.Core.HealthCheck.CustomHealthCheck, oneof: 0
  field :no_traffic_interval, 12, type: Google.Protobuf.Duration
  field :unhealthy_interval, 14, type: Google.Protobuf.Duration
  field :unhealthy_edge_interval, 15, type: Google.Protobuf.Duration
  field :healthy_edge_interval, 16, type: Google.Protobuf.Duration
  field :event_log_path, 17, type: :string
end

defmodule Envoy.Api.V2.Core.HealthCheck.Payload do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          payload: {atom, any}
        }
  defstruct [:payload]

  oneof :payload, 0
  field :text, 1, type: :string, oneof: 0
  field :binary, 2, type: :bytes, oneof: 0
end

defmodule Envoy.Api.V2.Core.HealthCheck.HttpHealthCheck do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          host: String.t(),
          path: String.t(),
          send: Envoy.Api.V2.Core.HealthCheck.Payload.t(),
          receive: Envoy.Api.V2.Core.HealthCheck.Payload.t(),
          service_name: String.t(),
          request_headers_to_add: [Envoy.Api.V2.Core.HeaderValueOption.t()],
          request_headers_to_remove: [String.t()],
          use_http2: boolean
        }
  defstruct [
    :host,
    :path,
    :send,
    :receive,
    :service_name,
    :request_headers_to_add,
    :request_headers_to_remove,
    :use_http2
  ]

  field :host, 1, type: :string
  field :path, 2, type: :string
  field :send, 3, type: Envoy.Api.V2.Core.HealthCheck.Payload
  field :receive, 4, type: Envoy.Api.V2.Core.HealthCheck.Payload
  field :service_name, 5, type: :string
  field :request_headers_to_add, 6, repeated: true, type: Envoy.Api.V2.Core.HeaderValueOption
  field :request_headers_to_remove, 8, repeated: true, type: :string
  field :use_http2, 7, type: :bool
end

defmodule Envoy.Api.V2.Core.HealthCheck.TcpHealthCheck do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          send: Envoy.Api.V2.Core.HealthCheck.Payload.t(),
          receive: [Envoy.Api.V2.Core.HealthCheck.Payload.t()]
        }
  defstruct [:send, :receive]

  field :send, 1, type: Envoy.Api.V2.Core.HealthCheck.Payload
  field :receive, 2, repeated: true, type: Envoy.Api.V2.Core.HealthCheck.Payload
end

defmodule Envoy.Api.V2.Core.HealthCheck.RedisHealthCheck do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t()
        }
  defstruct [:key]

  field :key, 1, type: :string
end

defmodule Envoy.Api.V2.Core.HealthCheck.GrpcHealthCheck do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          service_name: String.t()
        }
  defstruct [:service_name]

  field :service_name, 1, type: :string
end

defmodule Envoy.Api.V2.Core.HealthCheck.CustomHealthCheck do
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

defmodule Envoy.Api.V2.Core.HealthStatus do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :UNKNOWN, 0
  field :HEALTHY, 1
  field :UNHEALTHY, 2
  field :DRAINING, 3
  field :TIMEOUT, 4
end
