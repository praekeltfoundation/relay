defmodule Envoy.Config.Filter.Accesslog.V2.AccessLog do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          filter: Envoy.Config.Filter.Accesslog.V2.AccessLogFilter.t(),
          config: Google.Protobuf.Struct.t()
        }
  defstruct [:name, :filter, :config]

  field :name, 1, type: :string
  field :filter, 2, type: Envoy.Config.Filter.Accesslog.V2.AccessLogFilter
  field :config, 3, type: Google.Protobuf.Struct
end

defmodule Envoy.Config.Filter.Accesslog.V2.AccessLogFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filter_specifier: {atom, any}
        }
  defstruct [:filter_specifier]

  oneof :filter_specifier, 0
  field :status_code_filter, 1, type: Envoy.Config.Filter.Accesslog.V2.StatusCodeFilter, oneof: 0
  field :duration_filter, 2, type: Envoy.Config.Filter.Accesslog.V2.DurationFilter, oneof: 0

  field :not_health_check_filter, 3,
    type: Envoy.Config.Filter.Accesslog.V2.NotHealthCheckFilter,
    oneof: 0

  field :traceable_filter, 4, type: Envoy.Config.Filter.Accesslog.V2.TraceableFilter, oneof: 0
  field :runtime_filter, 5, type: Envoy.Config.Filter.Accesslog.V2.RuntimeFilter, oneof: 0
  field :and_filter, 6, type: Envoy.Config.Filter.Accesslog.V2.AndFilter, oneof: 0
  field :or_filter, 7, type: Envoy.Config.Filter.Accesslog.V2.OrFilter, oneof: 0
  field :header_filter, 8, type: Envoy.Config.Filter.Accesslog.V2.HeaderFilter, oneof: 0

  field :response_flag_filter, 9,
    type: Envoy.Config.Filter.Accesslog.V2.ResponseFlagFilter,
    oneof: 0
end

defmodule Envoy.Config.Filter.Accesslog.V2.ComparisonFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          op: integer,
          value: Envoy.Api.V2.Core.RuntimeUInt32.t()
        }
  defstruct [:op, :value]

  field :op, 1, type: Envoy.Config.Filter.Accesslog.V2.ComparisonFilter.Op, enum: true
  field :value, 2, type: Envoy.Api.V2.Core.RuntimeUInt32
end

defmodule Envoy.Config.Filter.Accesslog.V2.ComparisonFilter.Op do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :EQ, 0
  field :GE, 1
  field :LE, 2
end

defmodule Envoy.Config.Filter.Accesslog.V2.StatusCodeFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          comparison: Envoy.Config.Filter.Accesslog.V2.ComparisonFilter.t()
        }
  defstruct [:comparison]

  field :comparison, 1, type: Envoy.Config.Filter.Accesslog.V2.ComparisonFilter
end

defmodule Envoy.Config.Filter.Accesslog.V2.DurationFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          comparison: Envoy.Config.Filter.Accesslog.V2.ComparisonFilter.t()
        }
  defstruct [:comparison]

  field :comparison, 1, type: Envoy.Config.Filter.Accesslog.V2.ComparisonFilter
end

defmodule Envoy.Config.Filter.Accesslog.V2.NotHealthCheckFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule Envoy.Config.Filter.Accesslog.V2.TraceableFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule Envoy.Config.Filter.Accesslog.V2.RuntimeFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          runtime_key: String.t(),
          percent_sampled: Envoy.Type.FractionalPercent.t(),
          use_independent_randomness: boolean
        }
  defstruct [:runtime_key, :percent_sampled, :use_independent_randomness]

  field :runtime_key, 1, type: :string
  field :percent_sampled, 2, type: Envoy.Type.FractionalPercent
  field :use_independent_randomness, 3, type: :bool
end

defmodule Envoy.Config.Filter.Accesslog.V2.AndFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filters: [Envoy.Config.Filter.Accesslog.V2.AccessLogFilter.t()]
        }
  defstruct [:filters]

  field :filters, 1, repeated: true, type: Envoy.Config.Filter.Accesslog.V2.AccessLogFilter
end

defmodule Envoy.Config.Filter.Accesslog.V2.OrFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filters: [Envoy.Config.Filter.Accesslog.V2.AccessLogFilter.t()]
        }
  defstruct [:filters]

  field :filters, 2, repeated: true, type: Envoy.Config.Filter.Accesslog.V2.AccessLogFilter
end

defmodule Envoy.Config.Filter.Accesslog.V2.HeaderFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          header: Envoy.Api.V2.Route.HeaderMatcher.t()
        }
  defstruct [:header]

  field :header, 1, type: Envoy.Api.V2.Route.HeaderMatcher
end

defmodule Envoy.Config.Filter.Accesslog.V2.ResponseFlagFilter do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          flags: [String.t()]
        }
  defstruct [:flags]

  field :flags, 1, repeated: true, type: :string
end
