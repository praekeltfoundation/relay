defmodule Envoy.Api.V2.Core.ApiConfigSource do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          api_type: integer,
          cluster_names: [String.t()],
          grpc_services: [Envoy.Api.V2.Core.GrpcService.t()],
          refresh_delay: Google.Protobuf.Duration.t() | nil,
          request_timeout: Google.Protobuf.Duration.t() | nil
        }
  defstruct [:api_type, :cluster_names, :grpc_services, :refresh_delay, :request_timeout]

  field :api_type, 1, type: Envoy.Api.V2.Core.ApiConfigSource.ApiType, enum: true
  field :cluster_names, 2, repeated: true, type: :string
  field :grpc_services, 4, repeated: true, type: Envoy.Api.V2.Core.GrpcService
  field :refresh_delay, 3, type: Google.Protobuf.Duration
  field :request_timeout, 5, type: Google.Protobuf.Duration
end

defmodule Envoy.Api.V2.Core.ApiConfigSource.ApiType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :REST_LEGACY, 0
  field :REST, 1
  field :GRPC, 2
end

defmodule Envoy.Api.V2.Core.AggregatedConfigSource do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []
end

defmodule Envoy.Api.V2.Core.ConfigSource do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          config_source_specifier: {atom, any}
        }
  defstruct [:config_source_specifier]

  oneof :config_source_specifier, 0
  field :path, 1, type: :string, oneof: 0
  field :api_config_source, 2, type: Envoy.Api.V2.Core.ApiConfigSource, oneof: 0
  field :ads, 3, type: Envoy.Api.V2.Core.AggregatedConfigSource, oneof: 0
end
