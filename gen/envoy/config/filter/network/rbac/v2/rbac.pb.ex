defmodule Envoy.Config.Filter.Network.Rbac.V2.RBAC do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          rules: Envoy.Config.Rbac.V2alpha.RBAC.t(),
          shadow_rules: Envoy.Config.Rbac.V2alpha.RBAC.t(),
          stat_prefix: String.t()
        }
  defstruct [:rules, :shadow_rules, :stat_prefix]

  field :rules, 1, type: Envoy.Config.Rbac.V2alpha.RBAC
  field :shadow_rules, 2, type: Envoy.Config.Rbac.V2alpha.RBAC
  field :stat_prefix, 3, type: :string
end
