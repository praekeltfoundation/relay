defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtProvider do
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

defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.ProviderWithAudiences do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          provider_name: String.t(),
          audiences: [String.t()]
        }
  defstruct [:provider_name, :audiences]

  field :provider_name, 1, type: :string
  field :audiences, 2, repeated: true, type: :string
end

defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirement do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          requires_type: {atom, any}
        }
  defstruct [:requires_type]

  oneof :requires_type, 0
  field :provider_name, 1, type: :string, oneof: 0

  field :provider_and_audiences, 2,
    type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.ProviderWithAudiences,
    oneof: 0

  field :requires_any, 3,
    type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirementOrList,
    oneof: 0

  field :requires_all, 4,
    type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirementAndList,
    oneof: 0

  field :allow_missing_or_failed, 5, type: Google.Protobuf.Empty, oneof: 0
end

defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirementOrList do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          requirements: [Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirement.t()]
        }
  defstruct [:requirements]

  field :requirements, 1,
    repeated: true,
    type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirement
end

defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirementAndList do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          requirements: [Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirement.t()]
        }
  defstruct [:requirements]

  field :requirements, 1,
    repeated: true,
    type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirement
end

defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.RequirementRule do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          match: Envoy.Api.V2.Route.RouteMatch.t(),
          requires: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirement.t()
        }
  defstruct [:match, :requires]

  field :match, 1, type: Envoy.Api.V2.Route.RouteMatch
  field :requires, 2, type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtRequirement
end

defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtAuthentication do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          providers: %{String.t() => Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtProvider.t()},
          rules: [Envoy.Config.Filter.Http.JwtAuthn.V2alpha.RequirementRule.t()]
        }
  defstruct [:providers, :rules]

  field :providers, 1,
    repeated: true,
    type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtAuthentication.ProvidersEntry,
    map: true

  field :rules, 2, repeated: true, type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.RequirementRule
end

defmodule Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtAuthentication.ProvidersEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtProvider.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Envoy.Config.Filter.Http.JwtAuthn.V2alpha.JwtProvider
end
