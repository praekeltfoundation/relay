defmodule Envoy.Api.V2.Core.GrpcService do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          target_specifier: {atom, any},
          timeout: Google.Protobuf.Duration.t(),
          initial_metadata: [Envoy.Api.V2.Core.HeaderValue.t()]
        }
  defstruct [:target_specifier, :timeout, :initial_metadata]

  oneof :target_specifier, 0
  field :envoy_grpc, 1, type: Envoy.Api.V2.Core.GrpcService.EnvoyGrpc, oneof: 0
  field :google_grpc, 2, type: Envoy.Api.V2.Core.GrpcService.GoogleGrpc, oneof: 0
  field :timeout, 3, type: Google.Protobuf.Duration
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
          channel_credentials: Envoy.Api.V2.Core.GrpcService.GoogleGrpc.ChannelCredentials.t(),
          call_credentials: [Envoy.Api.V2.Core.GrpcService.GoogleGrpc.CallCredentials.t()],
          stat_prefix: String.t(),
          credentials_factory_name: String.t(),
          config: Google.Protobuf.Struct.t()
        }
  defstruct [
    :target_uri,
    :channel_credentials,
    :call_credentials,
    :stat_prefix,
    :credentials_factory_name,
    :config
  ]

  field :target_uri, 1, type: :string
  field :channel_credentials, 2, type: Envoy.Api.V2.Core.GrpcService.GoogleGrpc.ChannelCredentials

  field :call_credentials, 3,
    repeated: true,
    type: Envoy.Api.V2.Core.GrpcService.GoogleGrpc.CallCredentials

  field :stat_prefix, 4, type: :string
  field :credentials_factory_name, 5, type: :string
  field :config, 6, type: Google.Protobuf.Struct
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

defmodule Envoy.Api.V2.Core.GrpcService.GoogleGrpc.ChannelCredentials do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          credential_specifier: {atom, any}
        }
  defstruct [:credential_specifier]

  oneof :credential_specifier, 0

  field :ssl_credentials, 1,
    type: Envoy.Api.V2.Core.GrpcService.GoogleGrpc.SslCredentials,
    oneof: 0

  field :google_default, 2, type: Google.Protobuf.Empty, oneof: 0
end

defmodule Envoy.Api.V2.Core.GrpcService.GoogleGrpc.CallCredentials do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          credential_specifier: {atom, any}
        }
  defstruct [:credential_specifier]

  oneof :credential_specifier, 0
  field :access_token, 1, type: :string, oneof: 0
  field :google_compute_engine, 2, type: Google.Protobuf.Empty, oneof: 0
  field :google_refresh_token, 3, type: :string, oneof: 0

  field :service_account_jwt_access, 4,
    type:
      Envoy.Api.V2.Core.GrpcService.GoogleGrpc.CallCredentials.ServiceAccountJWTAccessCredentials,
    oneof: 0

  field :google_iam, 5,
    type: Envoy.Api.V2.Core.GrpcService.GoogleGrpc.CallCredentials.GoogleIAMCredentials,
    oneof: 0

  field :from_plugin, 6,
    type: Envoy.Api.V2.Core.GrpcService.GoogleGrpc.CallCredentials.MetadataCredentialsFromPlugin,
    oneof: 0
end

defmodule Envoy.Api.V2.Core.GrpcService.GoogleGrpc.CallCredentials.ServiceAccountJWTAccessCredentials do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          json_key: String.t(),
          token_lifetime_seconds: non_neg_integer
        }
  defstruct [:json_key, :token_lifetime_seconds]

  field :json_key, 1, type: :string
  field :token_lifetime_seconds, 2, type: :uint64
end

defmodule Envoy.Api.V2.Core.GrpcService.GoogleGrpc.CallCredentials.GoogleIAMCredentials do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          authorization_token: String.t(),
          authority_selector: String.t()
        }
  defstruct [:authorization_token, :authority_selector]

  field :authorization_token, 1, type: :string
  field :authority_selector, 2, type: :string
end

defmodule Envoy.Api.V2.Core.GrpcService.GoogleGrpc.CallCredentials.MetadataCredentialsFromPlugin do
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
