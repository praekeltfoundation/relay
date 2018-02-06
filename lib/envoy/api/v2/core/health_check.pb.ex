defmodule Envoy.Api.V2.Core.HealthCheck do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    health_checker:      {atom, any},
    timeout:             Google.Protobuf.Duration.t,
    interval:            Google.Protobuf.Duration.t,
    interval_jitter:     Google.Protobuf.Duration.t,
    unhealthy_threshold: Google.Protobuf.UInt32Value.t,
    healthy_threshold:   Google.Protobuf.UInt32Value.t,
    alt_port:            Google.Protobuf.UInt32Value.t,
    reuse_connection:    Google.Protobuf.BoolValue.t
  }
  defstruct [:health_checker, :timeout, :interval, :interval_jitter, :unhealthy_threshold, :healthy_threshold, :alt_port, :reuse_connection]

  oneof :health_checker, 0
  field :timeout, 1, type: Google.Protobuf.Duration
  field :interval, 2, type: Google.Protobuf.Duration
  field :interval_jitter, 3, type: Google.Protobuf.Duration
  field :unhealthy_threshold, 4, type: Google.Protobuf.UInt32Value
  field :healthy_threshold, 5, type: Google.Protobuf.UInt32Value
  field :alt_port, 6, type: Google.Protobuf.UInt32Value
  field :reuse_connection, 7, type: Google.Protobuf.BoolValue
  field :http_health_check, 8, type: Envoy.Api.V2.Core.HealthCheck.HttpHealthCheck, oneof: 0
  field :tcp_health_check, 9, type: Envoy.Api.V2.Core.HealthCheck.TcpHealthCheck, oneof: 0
  field :redis_health_check, 10, type: Envoy.Api.V2.Core.HealthCheck.RedisHealthCheck, oneof: 0
  field :grpc_health_check, 11, type: Envoy.Api.V2.Core.HealthCheck.GrpcHealthCheck, oneof: 0
end

defmodule Envoy.Api.V2.Core.HealthCheck.Payload do
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
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    host:         String.t,
    path:         String.t,
    send:         Envoy.Api.V2.Core.HealthCheck.Payload.t,
    receive:      Envoy.Api.V2.Core.HealthCheck.Payload.t,
    service_name: String.t
  }
  defstruct [:host, :path, :send, :receive, :service_name]

  field :host, 1, type: :string
  field :path, 2, type: :string
  field :send, 3, type: Envoy.Api.V2.Core.HealthCheck.Payload
  field :receive, 4, type: Envoy.Api.V2.Core.HealthCheck.Payload
  field :service_name, 5, type: :string
end

defmodule Envoy.Api.V2.Core.HealthCheck.TcpHealthCheck do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    send:    Envoy.Api.V2.Core.HealthCheck.Payload.t,
    receive: [Envoy.Api.V2.Core.HealthCheck.Payload.t]
  }
  defstruct [:send, :receive]

  field :send, 1, type: Envoy.Api.V2.Core.HealthCheck.Payload
  field :receive, 2, repeated: true, type: Envoy.Api.V2.Core.HealthCheck.Payload
end

defmodule Envoy.Api.V2.Core.HealthCheck.RedisHealthCheck do
  use Protobuf, syntax: :proto3

  defstruct []

end

defmodule Envoy.Api.V2.Core.HealthCheck.GrpcHealthCheck do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    service_name: String.t
  }
  defstruct [:service_name]

  field :service_name, 1, type: :string
end

defmodule Envoy.Api.V2.Core.HealthStatus do
  use Protobuf, enum: true, syntax: :proto3

  field :UNKNOWN, 0
  field :HEALTHY, 1
  field :UNHEALTHY, 2
  field :DRAINING, 3
  field :TIMEOUT, 4
end
