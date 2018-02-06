defmodule Google.Protobuf.DoubleValue do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    value: float
  }
  defstruct [:value]

  field :value, 1, type: :double
end

defmodule Google.Protobuf.FloatValue do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    value: float
  }
  defstruct [:value]

  field :value, 1, type: :float
end

defmodule Google.Protobuf.Int64Value do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    value: integer
  }
  defstruct [:value]

  field :value, 1, type: :int64
end

defmodule Google.Protobuf.UInt64Value do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    value: non_neg_integer
  }
  defstruct [:value]

  field :value, 1, type: :uint64
end

defmodule Google.Protobuf.Int32Value do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    value: integer
  }
  defstruct [:value]

  field :value, 1, type: :int32
end

defmodule Google.Protobuf.UInt32Value do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    value: non_neg_integer
  }
  defstruct [:value]

  field :value, 1, type: :uint32
end

defmodule Google.Protobuf.BoolValue do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    value: boolean
  }
  defstruct [:value]

  field :value, 1, type: :bool
end

defmodule Google.Protobuf.StringValue do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    value: String.t
  }
  defstruct [:value]

  field :value, 1, type: :string
end

defmodule Google.Protobuf.BytesValue do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    value: String.t
  }
  defstruct [:value]

  field :value, 1, type: :bytes
end
