defmodule Envoy.Api.V2.Core.GrpcService do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          target_specifier: {atom, any},
          timeout: Google.Protobuf.Duration.t(),
          credentials: [Envoy.Api.V2.Core.GrpcService.Credentials.t()],
          initial_metadata: [Envoy.Api.V2.Core.HeaderValue.t()]
        }
  defstruct [:target_specifier, :timeout, :credentials, :initial_metadata]

  oneof :target_specifier, 0
  field :envoy_grpc, 1, type: Envoy.Api.V2.Core.GrpcService.EnvoyGrpc, oneof: 0
  field :google_grpc, 2, type: Envoy.Api.V2.Core.GrpcService.GoogleGrpc, oneof: 0
  field :timeout, 3, type: Google.Protobuf.Duration
  field :credentials, 4, repeated: true, type: Envoy.Api.V2.Core.GrpcService.Credentials
  field :initial_metadata, 5, repeated: true, type: Envoy.Api.V2.Core.HeaderValue
end

defmodule Envoy.Api.V2.Core.GrpcService.EnvoyGrpc do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          cluster_name: String.t()
        }
  defstruct [:cluster_name]

  field :cluster_name, 1, type: :string
end

defmodule Envoy.Api.V2.Core.GrpcService.GoogleGrpc do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          target_uri: String.t(),
          ssl_credentials: Envoy.Api.V2.Core.GrpcService.GoogleGrpc.SslCredentials.t(),
          stat_prefix: String.t(),
          config: Google.Protobuf.Struct.t()
        }
  defstruct [:target_uri, :ssl_credentials, :stat_prefix, :config]

  field :target_uri, 1, type: :string
  field :ssl_credentials, 2, type: Envoy.Api.V2.Core.GrpcService.GoogleGrpc.SslCredentials
  field :stat_prefix, 3, type: :string
  field :config, 4, type: Google.Protobuf.Struct
end

defmodule Envoy.Api.V2.Core.GrpcService.GoogleGrpc.SslCredentials do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          root_certs: Envoy.Api.V2.Core.DataSource.t(),
          private_key: Envoy.Api.V2.Core.DataSource.t(),
          cert_chain: Envoy.Api.V2.Core.DataSource.t()
        }
  defstruct [:root_certs, :private_key, :cert_chain]

  field :root_certs, 1, type: Envoy.Api.V2.Core.DataSource
  field :private_key, 2, type: Envoy.Api.V2.Core.DataSource
  field :cert_chain, 3, type: Envoy.Api.V2.Core.DataSource
end

defmodule Envoy.Api.V2.Core.GrpcService.Credentials do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          credential_specifier: {atom, any}
        }
  defstruct [:credential_specifier]

  oneof :credential_specifier, 0
  field :access_token, 1, type: :string, oneof: 0
end
