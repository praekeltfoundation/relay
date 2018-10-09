defmodule Envoy.Config.Filter.Http.Rbac.V2.RBAC do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          rules: Envoy.Config.Rbac.V2alpha.RBAC.t() | nil,
          shadow_rules: Envoy.Config.Rbac.V2alpha.RBAC.t() | nil
        }
  defstruct [:rules, :shadow_rules]

  field :rules, 1, type: Envoy.Config.Rbac.V2alpha.RBAC
  field :shadow_rules, 2, type: Envoy.Config.Rbac.V2alpha.RBAC
end

defmodule Envoy.Config.Filter.Http.Rbac.V2.RBACPerRoute do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          rbac: Envoy.Config.Filter.Http.Rbac.V2.RBAC.t() | nil
        }
  defstruct [:rbac]

  field :rbac, 2, type: Envoy.Config.Filter.Http.Rbac.V2.RBAC
end
