defmodule Envoy.Config.Filter.Network.TcpProxy.V2.TcpProxy do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    stat_prefix:             String.t,
    cluster:                 String.t,
    idle_timeout:            Google.Protobuf.Duration.t,
    downstream_idle_timeout: Google.Protobuf.Duration.t,
    upstream_idle_timeout:   Google.Protobuf.Duration.t,
    access_log:              [Envoy.Config.Filter.Accesslog.V2.AccessLog.t],
    deprecated_v1:           Envoy.Config.Filter.Network.TcpProxy.V2.TcpProxy.DeprecatedV1.t,
    max_connect_attempts:    Google.Protobuf.UInt32Value.t
  }
  defstruct [:stat_prefix, :cluster, :idle_timeout, :downstream_idle_timeout, :upstream_idle_timeout, :access_log, :deprecated_v1, :max_connect_attempts]

  field :stat_prefix, 1, type: :string
  field :cluster, 2, type: :string
  field :idle_timeout, 8, type: Google.Protobuf.Duration
  field :downstream_idle_timeout, 3, type: Google.Protobuf.Duration
  field :upstream_idle_timeout, 4, type: Google.Protobuf.Duration
  field :access_log, 5, repeated: true, type: Envoy.Config.Filter.Accesslog.V2.AccessLog
  field :deprecated_v1, 6, type: Envoy.Config.Filter.Network.TcpProxy.V2.TcpProxy.DeprecatedV1, deprecated: true
  field :max_connect_attempts, 7, type: Google.Protobuf.UInt32Value
end

defmodule Envoy.Config.Filter.Network.TcpProxy.V2.TcpProxy.DeprecatedV1 do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    routes: [Envoy.Config.Filter.Network.TcpProxy.V2.TcpProxy.DeprecatedV1.TCPRoute.t]
  }
  defstruct [:routes]

  field :routes, 1, repeated: true, type: Envoy.Config.Filter.Network.TcpProxy.V2.TcpProxy.DeprecatedV1.TCPRoute
end

defmodule Envoy.Config.Filter.Network.TcpProxy.V2.TcpProxy.DeprecatedV1.TCPRoute do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    cluster:             String.t,
    destination_ip_list: [Envoy.Api.V2.Core.CidrRange.t],
    destination_ports:   String.t,
    source_ip_list:      [Envoy.Api.V2.Core.CidrRange.t],
    source_ports:        String.t
  }
  defstruct [:cluster, :destination_ip_list, :destination_ports, :source_ip_list, :source_ports]

  field :cluster, 1, type: :string
  field :destination_ip_list, 2, repeated: true, type: Envoy.Api.V2.Core.CidrRange
  field :destination_ports, 3, type: :string
  field :source_ip_list, 4, repeated: true, type: Envoy.Api.V2.Core.CidrRange
  field :source_ports, 5, type: :string
end
