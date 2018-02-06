defmodule Envoy.Api.V2.Core.Locality do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    region:   String.t,
    zone:     String.t,
    sub_zone: String.t
  }
  defstruct [:region, :zone, :sub_zone]

  field :region, 1, type: :string
  field :zone, 2, type: :string
  field :sub_zone, 3, type: :string
end

defmodule Envoy.Api.V2.Core.Percent do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    value: float
  }
  defstruct [:value]

  field :value, 1, type: :double
end

defmodule Envoy.Api.V2.Core.Node do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    id:            String.t,
    cluster:       String.t,
    metadata:      Google.Protobuf.Struct.t,
    locality:      Envoy.Api.V2.Core.Locality.t,
    build_version: String.t
  }
  defstruct [:id, :cluster, :metadata, :locality, :build_version]

  field :id, 1, type: :string
  field :cluster, 2, type: :string
  field :metadata, 3, type: Google.Protobuf.Struct
  field :locality, 4, type: Envoy.Api.V2.Core.Locality
  field :build_version, 5, type: :string
end

defmodule Envoy.Api.V2.Core.Metadata do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    filter_metadata: %{String.t => Google.Protobuf.Struct.t}
  }
  defstruct [:filter_metadata]

  field :filter_metadata, 1, repeated: true, type: Envoy.Api.V2.Core.Metadata.FilterMetadataEntry, map: true
end

defmodule Envoy.Api.V2.Core.Metadata.FilterMetadataEntry do
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
    key:   String.t,
    value: Google.Protobuf.Struct.t
  }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Google.Protobuf.Struct
end

defmodule Envoy.Api.V2.Core.RuntimeUInt32 do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    default_value: non_neg_integer,
    runtime_key:   String.t
  }
  defstruct [:default_value, :runtime_key]

  field :default_value, 2, type: :uint32
  field :runtime_key, 3, type: :string
end

defmodule Envoy.Api.V2.Core.HeaderValue do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    key:   String.t,
    value: String.t
  }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Envoy.Api.V2.Core.HeaderValueOption do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    header: Envoy.Api.V2.Core.HeaderValue.t,
    append: Google.Protobuf.BoolValue.t
  }
  defstruct [:header, :append]

  field :header, 1, type: Envoy.Api.V2.Core.HeaderValue
  field :append, 2, type: Google.Protobuf.BoolValue
end

defmodule Envoy.Api.V2.Core.DataSource do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    specifier:     {atom, any}
  }
  defstruct [:specifier]

  oneof :specifier, 0
  field :filename, 1, type: :string, oneof: 0
  field :inline_bytes, 2, type: :bytes, oneof: 0
  field :inline_string, 3, type: :string, oneof: 0
end

defmodule Envoy.Api.V2.Core.TransportSocket do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    name:   String.t,
    config: Google.Protobuf.Struct.t
  }
  defstruct [:name, :config]

  field :name, 1, type: :string
  field :config, 2, type: Google.Protobuf.Struct
end

defmodule Envoy.Api.V2.Core.RoutingPriority do
  use Protobuf, enum: true, syntax: :proto3

  field :DEFAULT, 0
  field :HIGH, 1
end

defmodule Envoy.Api.V2.Core.RequestMethod do
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
