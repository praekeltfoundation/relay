defmodule Envoy.Api.V2.GrpcService do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    target_specifier: {atom, any},
    timeout:     Google.Protobuf.Duration.t,
    credentials: [Envoy.Api.V2.GrpcService.Credentials.t]
  }
  defstruct [:target_specifier, :timeout, :credentials]

  oneof :target_specifier, 0
  field :envoy_grpc, 1, type: Envoy.Api.V2.GrpcService.EnvoyGrpc, oneof: 0
  field :google_grpc, 2, type: Envoy.Api.V2.GrpcService.GoogleGrpc, oneof: 0
  field :timeout, 3, type: Google.Protobuf.Duration
  field :credentials, 4, repeated: true, type: Envoy.Api.V2.GrpcService.Credentials
end

defmodule Envoy.Api.V2.GrpcService.EnvoyGrpc do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    cluster_name: String.t
  }
  defstruct [:cluster_name]

  field :cluster_name, 1, type: :string
end

defmodule Envoy.Api.V2.GrpcService.GoogleGrpc do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    target_uri:      String.t,
    ssl_credentials: Envoy.Api.V2.GrpcService.GoogleGrpc.SslCredentials.t,
    stat_prefix:     String.t
  }
  defstruct [:target_uri, :ssl_credentials, :stat_prefix]

  field :target_uri, 1, type: :string
  field :ssl_credentials, 2, type: Envoy.Api.V2.GrpcService.GoogleGrpc.SslCredentials
  field :stat_prefix, 3, type: :string
end

defmodule Envoy.Api.V2.GrpcService.GoogleGrpc.SslCredentials do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    root_certs:  Envoy.Api.V2.DataSource.t,
    private_key: Envoy.Api.V2.DataSource.t,
    cert_chain:  Envoy.Api.V2.DataSource.t
  }
  defstruct [:root_certs, :private_key, :cert_chain]

  field :root_certs, 1, type: Envoy.Api.V2.DataSource
  field :private_key, 2, type: Envoy.Api.V2.DataSource
  field :cert_chain, 3, type: Envoy.Api.V2.DataSource
end

defmodule Envoy.Api.V2.GrpcService.Credentials do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    credential_specifier: {atom, any}
  }
  defstruct [:credential_specifier]

  oneof :credential_specifier, 0
  field :access_token, 1, type: :string, oneof: 0
end
