defmodule Envoy.Api.V2.Auth.TlsParameters do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    tls_minimum_protocol_version: integer,
    tls_maximum_protocol_version: integer,
    cipher_suites:                [String.t],
    ecdh_curves:                  [String.t]
  }
  defstruct [:tls_minimum_protocol_version, :tls_maximum_protocol_version, :cipher_suites, :ecdh_curves]

  field :tls_minimum_protocol_version, 1, type: Envoy.Api.V2.Auth.TlsParameters.TlsProtocol, enum: true
  field :tls_maximum_protocol_version, 2, type: Envoy.Api.V2.Auth.TlsParameters.TlsProtocol, enum: true
  field :cipher_suites, 3, repeated: true, type: :string
  field :ecdh_curves, 4, repeated: true, type: :string
end

defmodule Envoy.Api.V2.Auth.TlsParameters.TlsProtocol do
  use Protobuf, enum: true, syntax: :proto3

  field :TLS_AUTO, 0
  field :TLSv1_0, 1
  field :TLSv1_1, 2
  field :TLSv1_2, 3
  field :TLSv1_3, 4
end

defmodule Envoy.Api.V2.Auth.TlsCertificate do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    certificate_chain:            Envoy.Api.V2.Core.DataSource.t,
    private_key:                  Envoy.Api.V2.Core.DataSource.t,
    password:                     Envoy.Api.V2.Core.DataSource.t,
    ocsp_staple:                  Envoy.Api.V2.Core.DataSource.t,
    signed_certificate_timestamp: [Envoy.Api.V2.Core.DataSource.t]
  }
  defstruct [:certificate_chain, :private_key, :password, :ocsp_staple, :signed_certificate_timestamp]

  field :certificate_chain, 1, type: Envoy.Api.V2.Core.DataSource
  field :private_key, 2, type: Envoy.Api.V2.Core.DataSource
  field :password, 3, type: Envoy.Api.V2.Core.DataSource
  field :ocsp_staple, 4, type: Envoy.Api.V2.Core.DataSource
  field :signed_certificate_timestamp, 5, repeated: true, type: Envoy.Api.V2.Core.DataSource
end

defmodule Envoy.Api.V2.Auth.TlsSessionTicketKeys do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    keys: [Envoy.Api.V2.Core.DataSource.t]
  }
  defstruct [:keys]

  field :keys, 1, repeated: true, type: Envoy.Api.V2.Core.DataSource
end

defmodule Envoy.Api.V2.Auth.CertificateValidationContext do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    trusted_ca:                           Envoy.Api.V2.Core.DataSource.t,
    verify_certificate_hash:              [String.t],
    verify_spki_sha256:                   [String.t],
    verify_subject_alt_name:              [String.t],
    require_ocsp_staple:                  Google.Protobuf.BoolValue.t,
    require_signed_certificate_timestamp: Google.Protobuf.BoolValue.t,
    crl:                                  Envoy.Api.V2.Core.DataSource.t
  }
  defstruct [:trusted_ca, :verify_certificate_hash, :verify_spki_sha256, :verify_subject_alt_name, :require_ocsp_staple, :require_signed_certificate_timestamp, :crl]

  field :trusted_ca, 1, type: Envoy.Api.V2.Core.DataSource
  field :verify_certificate_hash, 2, repeated: true, type: :string
  field :verify_spki_sha256, 3, repeated: true, type: :string
  field :verify_subject_alt_name, 4, repeated: true, type: :string
  field :require_ocsp_staple, 5, type: Google.Protobuf.BoolValue
  field :require_signed_certificate_timestamp, 6, type: Google.Protobuf.BoolValue
  field :crl, 7, type: Envoy.Api.V2.Core.DataSource
end

defmodule Envoy.Api.V2.Auth.CommonTlsContext do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    tls_params:                         Envoy.Api.V2.Auth.TlsParameters.t,
    tls_certificates:                   [Envoy.Api.V2.Auth.TlsCertificate.t],
    tls_certificate_sds_secret_configs: [Envoy.Api.V2.Auth.SdsSecretConfig.t],
    validation_context:                 Envoy.Api.V2.Auth.CertificateValidationContext.t,
    alpn_protocols:                     [String.t],
    deprecated_v1:                      Envoy.Api.V2.Auth.CommonTlsContext.DeprecatedV1.t
  }
  defstruct [:tls_params, :tls_certificates, :tls_certificate_sds_secret_configs, :validation_context, :alpn_protocols, :deprecated_v1]

  field :tls_params, 1, type: Envoy.Api.V2.Auth.TlsParameters
  field :tls_certificates, 2, repeated: true, type: Envoy.Api.V2.Auth.TlsCertificate
  field :tls_certificate_sds_secret_configs, 6, repeated: true, type: Envoy.Api.V2.Auth.SdsSecretConfig
  field :validation_context, 3, type: Envoy.Api.V2.Auth.CertificateValidationContext
  field :alpn_protocols, 4, repeated: true, type: :string
  field :deprecated_v1, 5, type: Envoy.Api.V2.Auth.CommonTlsContext.DeprecatedV1, deprecated: true
end

defmodule Envoy.Api.V2.Auth.CommonTlsContext.DeprecatedV1 do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    alt_alpn_protocols: String.t
  }
  defstruct [:alt_alpn_protocols]

  field :alt_alpn_protocols, 1, type: :string
end

defmodule Envoy.Api.V2.Auth.UpstreamTlsContext do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    common_tls_context: Envoy.Api.V2.Auth.CommonTlsContext.t,
    sni:                String.t
  }
  defstruct [:common_tls_context, :sni]

  field :common_tls_context, 1, type: Envoy.Api.V2.Auth.CommonTlsContext
  field :sni, 2, type: :string
end

defmodule Envoy.Api.V2.Auth.DownstreamTlsContext do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    session_ticket_keys_type:              {atom, any},
    common_tls_context:                    Envoy.Api.V2.Auth.CommonTlsContext.t,
    require_client_certificate:            Google.Protobuf.BoolValue.t,
    require_sni:                           Google.Protobuf.BoolValue.t
  }
  defstruct [:session_ticket_keys_type, :common_tls_context, :require_client_certificate, :require_sni]

  oneof :session_ticket_keys_type, 0
  field :common_tls_context, 1, type: Envoy.Api.V2.Auth.CommonTlsContext
  field :require_client_certificate, 2, type: Google.Protobuf.BoolValue
  field :require_sni, 3, type: Google.Protobuf.BoolValue
  field :session_ticket_keys, 4, type: Envoy.Api.V2.Auth.TlsSessionTicketKeys, oneof: 0
  field :session_ticket_keys_sds_secret_config, 5, type: Envoy.Api.V2.Auth.SdsSecretConfig, oneof: 0
end

defmodule Envoy.Api.V2.Auth.SdsSecretConfig do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    name:       String.t,
    sds_config: Envoy.Api.V2.Core.ConfigSource.t
  }
  defstruct [:name, :sds_config]

  field :name, 1, type: :string
  field :sds_config, 2, type: Envoy.Api.V2.Core.ConfigSource
end

defmodule Envoy.Api.V2.Auth.Secret do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    type:                {atom, any},
    name:                String.t
  }
  defstruct [:type, :name]

  oneof :type, 0
  field :name, 1, type: :string
  field :tls_certificate, 2, type: Envoy.Api.V2.Auth.TlsCertificate, oneof: 0
  field :session_ticket_keys, 3, type: Envoy.Api.V2.Auth.TlsSessionTicketKeys, oneof: 0
end
