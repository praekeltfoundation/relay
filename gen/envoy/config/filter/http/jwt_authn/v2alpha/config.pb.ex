defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRule do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          jwks_source_specifier: {atom, any},
          issuer: String.t(),
          audiences: [String.t()],
          forward: boolean,
          from_headers: [Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtHeader.t()],
          from_params: [String.t()],
          forward_payload_header: String.t()
        }
  defstruct [
    :jwks_source_specifier,
    :issuer,
    :audiences,
    :forward,
    :from_headers,
    :from_params,
    :forward_payload_header
  ]

  oneof :jwks_source_specifier, 0
  field :issuer, 1, type: :string
  field :audiences, 2, repeated: true, type: :string
  field :remote_jwks, 3, type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.RemoteJwks, oneof: 0
  field :local_jwks, 4, type: Envoy.Api.V2.Core.DataSource, oneof: 0
  field :forward, 5, type: :bool

  field :from_headers, 6,
    repeated: true,
    type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtHeader

  field :from_params, 7, repeated: true, type: :string
  field :forward_payload_header, 8, type: :string
end

defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.RemoteJwks do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          http_uri: Envoy.Api.V2.Core.HttpUri.t(),
          cache_duration: Google.Protobuf.Duration.t()
        }
  defstruct [:http_uri, :cache_duration]

  field :http_uri, 1, type: Envoy.Api.V2.Core.HttpUri
  field :cache_duration, 2, type: Google.Protobuf.Duration
end

defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtHeader do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          value_prefix: String.t()
        }
  defstruct [:name, :value_prefix]

  field :name, 1, type: :string
  field :value_prefix, 2, type: :string
end

defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtAuthentication do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          rules: [Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRule.t()],
          allow_missing_or_failed: boolean,
          bypass: [Envoy.Api.V2.Route.RouteMatch.t()]
        }
  defstruct [:rules, :allow_missing_or_failed, :bypass]

  field :rules, 1, repeated: true, type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRule
  field :allow_missing_or_failed, 2, type: :bool
  field :bypass, 3, repeated: true, type: Envoy.Api.V2.Route.RouteMatch
end
