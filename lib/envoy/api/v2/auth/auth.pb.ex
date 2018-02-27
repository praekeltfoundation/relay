defmodule Envoy.Api.V2.Auth.AuthAction do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          action_type: integer,
          rules: [Envoy.Api.V2.Auth.AuthAction.Rule.t()]
        }
  defstruct [:action_type, :rules]

  field :action_type, 1, type: Envoy.Api.V2.Auth.AuthAction.ActionType, enum: true
  field :rules, 2, repeated: true, type: Envoy.Api.V2.Auth.AuthAction.Rule
end

defmodule Envoy.Api.V2.Auth.AuthAction.AndRule do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          rules: [Envoy.Api.V2.Auth.AuthAction.Rule.t()]
        }
  defstruct [:rules]

  field :rules, 1, repeated: true, type: Envoy.Api.V2.Auth.AuthAction.Rule
end

defmodule Envoy.Api.V2.Auth.AuthAction.OrRule do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          rules: [Envoy.Api.V2.Auth.AuthAction.Rule.t()]
        }
  defstruct [:rules]

  field :rules, 1, repeated: true, type: Envoy.Api.V2.Auth.AuthAction.Rule
end

defmodule Envoy.Api.V2.Auth.AuthAction.X509Rule do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          validation_context: Envoy.Api.V2.Auth.CertificateValidationContext.t()
        }
  defstruct [:validation_context]

  field :validation_context, 3, type: Envoy.Api.V2.Auth.CertificateValidationContext
end

defmodule Envoy.Api.V2.Auth.AuthAction.Rule do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          rule_specifier: {atom, any}
        }
  defstruct [:rule_specifier]

  oneof :rule_specifier, 0
  field :and_rule, 1, type: Envoy.Api.V2.Auth.AuthAction.AndRule, oneof: 0
  field :or_rule, 2, type: Envoy.Api.V2.Auth.AuthAction.OrRule, oneof: 0
  field :x509_rule, 3, type: Envoy.Api.V2.Auth.AuthAction.X509Rule, oneof: 0
end

defmodule Envoy.Api.V2.Auth.AuthAction.ActionType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :ALLOW, 0
  field :DENY, 1
end
