defmodule Envoy.Api.V2.Core.Locality do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          region: String.t(),
          zone: String.t(),
          sub_zone: String.t()
        }
  defstruct [:region, :zone, :sub_zone]

  field :region, 1, type: :string
  field :zone, 2, type: :string
  field :sub_zone, 3, type: :string
end

defmodule Envoy.Api.V2.Core.Node do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          id: String.t(),
          cluster: String.t(),
          metadata: Google.Protobuf.Struct.t() | nil,
          locality: Envoy.Api.V2.Core.Locality.t() | nil,
          build_version: String.t()
        }
  defstruct [:id, :cluster, :metadata, :locality, :build_version]

  field :id, 1, type: :string
  field :cluster, 2, type: :string
  field :metadata, 3, type: Google.Protobuf.Struct
  field :locality, 4, type: Envoy.Api.V2.Core.Locality
  field :build_version, 5, type: :string
end

defmodule Envoy.Api.V2.Core.Metadata do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filter_metadata: %{String.t() => Google.Protobuf.Struct.t() | nil}
        }
  defstruct [:filter_metadata]

  field :filter_metadata, 1,
    repeated: true,
    type: Envoy.Api.V2.Core.Metadata.FilterMetadataEntry,
    map: true
end

defmodule Envoy.Api.V2.Core.Metadata.FilterMetadataEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Google.Protobuf.Struct.t() | nil
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Google.Protobuf.Struct
end

defmodule Envoy.Api.V2.Core.RuntimeUInt32 do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          default_value: non_neg_integer,
          runtime_key: String.t()
        }
  defstruct [:default_value, :runtime_key]

  field :default_value, 2, type: :uint32
  field :runtime_key, 3, type: :string
end

defmodule Envoy.Api.V2.Core.HeaderValue do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Envoy.Api.V2.Core.HeaderValueOption do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          header: Envoy.Api.V2.Core.HeaderValue.t() | nil,
          append: Google.Protobuf.BoolValue.t() | nil
        }
  defstruct [:header, :append]

  field :header, 1, type: Envoy.Api.V2.Core.HeaderValue
  field :append, 2, type: Google.Protobuf.BoolValue
end

defmodule Envoy.Api.V2.Core.DataSource do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          specifier: {atom, any}
        }
  defstruct [:specifier]

  oneof :specifier, 0
  field :filename, 1, type: :string, oneof: 0
  field :inline_bytes, 2, type: :bytes, oneof: 0
  field :inline_string, 3, type: :string, oneof: 0
end

defmodule Envoy.Api.V2.Core.TransportSocket do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          config: Google.Protobuf.Struct.t() | nil
        }
  defstruct [:name, :config]

  field :name, 1, type: :string
  field :config, 2, type: Google.Protobuf.Struct
end

defmodule Envoy.Api.V2.Core.SocketOption do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          value: {atom, any},
          description: String.t(),
          level: integer,
          name: integer,
          state: integer
        }
  defstruct [:value, :description, :level, :name, :state]

  oneof :value, 0
  field :description, 1, type: :string
  field :level, 2, type: :int64
  field :name, 3, type: :int64
  field :int_value, 4, type: :int64, oneof: 0
  field :buf_value, 5, type: :bytes, oneof: 0
  field :state, 6, type: Envoy.Api.V2.Core.SocketOption.SocketState, enum: true
end

defmodule Envoy.Api.V2.Core.SocketOption.SocketState do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :STATE_PREBIND, 0
  field :STATE_BOUND, 1
  field :STATE_LISTENING, 2
end

defmodule Envoy.Api.V2.Core.RuntimeFractionalPercent do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          default_value: Envoy.Type.FractionalPercent.t() | nil,
          runtime_key: String.t()
        }
  defstruct [:default_value, :runtime_key]

  field :default_value, 1, type: Envoy.Type.FractionalPercent
  field :runtime_key, 2, type: :string
end

defmodule Envoy.Api.V2.Core.RoutingPriority do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :DEFAULT, 0
  field :HIGH, 1
end

defmodule Envoy.Api.V2.Core.RequestMethod do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :METHOD_UNSPECIFIED, 0
  field :GET, 1
  field :HEAD, 2
  field :POST, 3
  field :PUT, 4
  field :DELETE, 5
  field :CONNECT, 6
  field :OPTIONS, 7
  field :TRACE, 8
end
