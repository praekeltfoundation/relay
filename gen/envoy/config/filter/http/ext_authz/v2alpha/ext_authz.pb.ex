defmodule Envoy.Config.Filter.Http.ExtAuthz.V2alpha.HttpService do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          server_uri: Envoy.Api.V2.Core.HttpUri.t(),
          path_prefix: String.t()
        }
  defstruct [:server_uri, :path_prefix]

  field :server_uri, 1, type: Envoy.Api.V2.Core.HttpUri
  field :path_prefix, 2, type: :string
end

defmodule Envoy.Config.Filter.Http.ExtAuthz.V2alpha.ExtAuthz do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          services: {atom, any},
          failure_mode_allow: boolean
        }
  defstruct [:services, :failure_mode_allow]

  oneof :services, 0
  field :grpc_service, 1, type: Envoy.Api.V2.Core.GrpcService, oneof: 0
  field :http_service, 3, type: Envoy.Config.Filter.Http.ExtAuthz.V2alpha.HttpService, oneof: 0
  field :failure_mode_allow, 2, type: :bool
end
