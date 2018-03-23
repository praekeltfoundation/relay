defmodule Envoy.Config.Trace.V2.Tracing do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          http: Envoy.Config.Trace.V2.Tracing.Http.t()
        }
  defstruct [:http]

  field :http, 1, type: Envoy.Config.Trace.V2.Tracing.Http
end

defmodule Envoy.Config.Trace.V2.Tracing.Http do
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

defmodule Envoy.Config.Trace.V2.LightstepConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          collector_cluster: String.t(),
          access_token_file: String.t()
        }
  defstruct [:collector_cluster, :access_token_file]

  field :collector_cluster, 1, type: :string
  field :access_token_file, 2, type: :string
end

defmodule Envoy.Config.Trace.V2.ZipkinConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          collector_cluster: String.t(),
          collector_endpoint: String.t()
        }
  defstruct [:collector_cluster, :collector_endpoint]

  field :collector_cluster, 1, type: :string
  field :collector_endpoint, 2, type: :string
end

defmodule Envoy.Config.Trace.V2.DynamicOtConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          library: String.t(),
          config: Google.Protobuf.Struct.t()
        }
  defstruct [:library, :config]

  field :library, 1, type: :string
  field :config, 2, type: Google.Protobuf.Struct
end

defmodule Envoy.Config.Trace.V2.TraceServiceConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          grpc_service: Envoy.Api.V2.Core.GrpcService.t()
        }
  defstruct [:grpc_service]

  field :grpc_service, 1, type: Envoy.Api.V2.Core.GrpcService
end
