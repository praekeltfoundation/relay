defmodule Envoy.Api.V2.ApiConfigSource do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    api_type:      integer,
    cluster_names: [String.t],
    grpc_services: [Envoy.Api.V2.GrpcService.t],
    refresh_delay: Google.Protobuf.Duration.t
  }
  defstruct [:api_type, :cluster_names, :grpc_services, :refresh_delay]

  field :api_type, 1, type: Envoy.Api.V2.ApiConfigSource.ApiType, enum: true
  field :cluster_names, 2, repeated: true, type: :string
  field :grpc_services, 4, repeated: true, type: Envoy.Api.V2.GrpcService
  field :refresh_delay, 3, type: Google.Protobuf.Duration
end

defmodule Envoy.Api.V2.ApiConfigSource.ApiType do
  use Protobuf, enum: true, syntax: :proto3

  field :REST_LEGACY, 0
  field :REST, 1
  field :GRPC, 2
end

defmodule Envoy.Api.V2.AggregatedConfigSource do
  use Protobuf, syntax: :proto3

  defstruct []

end

defmodule Envoy.Api.V2.ConfigSource do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    config_source_specifier: {atom, any}
  }
  defstruct [:config_source_specifier]

  oneof :config_source_specifier, 0
  field :path, 1, type: :string, oneof: 0
  field :api_config_source, 2, type: Envoy.Api.V2.ApiConfigSource, oneof: 0
  field :ads, 3, type: Envoy.Api.V2.AggregatedConfigSource, oneof: 0
end
