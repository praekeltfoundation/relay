defmodule Envoy.Api.V2.Core.Pipe do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          path: String.t()
        }
  defstruct [:path]

  field :path, 1, type: :string
end

defmodule Envoy.Api.V2.Core.SocketAddress do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          port_specifier: {atom, any},
          protocol: integer,
          address: String.t(),
          resolver_name: String.t(),
          ipv4_compat: boolean
        }
  defstruct [:port_specifier, :protocol, :address, :resolver_name, :ipv4_compat]

  oneof :port_specifier, 0
  field :protocol, 1, type: Envoy.Api.V2.Core.SocketAddress.Protocol, enum: true
  field :address, 2, type: :string
  field :port_value, 3, type: :uint32, oneof: 0
  field :named_port, 4, type: :string, oneof: 0
  field :resolver_name, 5, type: :string
  field :ipv4_compat, 6, type: :bool
end

defmodule Envoy.Api.V2.Core.SocketAddress.Protocol do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :TCP, 0
  field :UDP, 1
end

defmodule Envoy.Api.V2.Core.TcpKeepalive do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          keepalive_probes: Google.Protobuf.UInt32Value.t(),
          keepalive_time: Google.Protobuf.UInt32Value.t(),
          keepalive_interval: Google.Protobuf.UInt32Value.t()
        }
  defstruct [:keepalive_probes, :keepalive_time, :keepalive_interval]

  field :keepalive_probes, 1, type: Google.Protobuf.UInt32Value
  field :keepalive_time, 2, type: Google.Protobuf.UInt32Value
  field :keepalive_interval, 3, type: Google.Protobuf.UInt32Value
end

defmodule Envoy.Api.V2.Core.BindConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          source_address: Envoy.Api.V2.Core.SocketAddress.t(),
          freebind: Google.Protobuf.BoolValue.t()
        }
  defstruct [:source_address, :freebind]

  field :source_address, 1, type: Envoy.Api.V2.Core.SocketAddress
  field :freebind, 2, type: Google.Protobuf.BoolValue
end

defmodule Envoy.Api.V2.Core.Address do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          address: {atom, any}
        }
  defstruct [:address]

  oneof :address, 0
  field :socket_address, 1, type: Envoy.Api.V2.Core.SocketAddress, oneof: 0
  field :pipe, 2, type: Envoy.Api.V2.Core.Pipe, oneof: 0
end

defmodule Envoy.Api.V2.Core.CidrRange do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          address_prefix: String.t(),
          prefix_len: Google.Protobuf.UInt32Value.t()
        }
  defstruct [:address_prefix, :prefix_len]

  field :address_prefix, 1, type: :string
  field :prefix_len, 2, type: Google.Protobuf.UInt32Value
end
