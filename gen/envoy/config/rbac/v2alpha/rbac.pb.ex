defmodule Envoy.Config.Rbac.V2alpha.RBAC do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          action: integer,
          policies: %{String.t() => Envoy.Config.Rbac.V2alpha.Policy.t()}
        }
  defstruct [:action, :policies]

  field :action, 1, type: Envoy.Config.Rbac.V2alpha.RBAC.Action, enum: true

  field :policies, 2,
    repeated: true,
    type: Envoy.Config.Rbac.V2alpha.RBAC.PoliciesEntry,
    map: true
end

defmodule Envoy.Config.Rbac.V2alpha.RBAC.PoliciesEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Envoy.Config.Rbac.V2alpha.Policy.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Envoy.Config.Rbac.V2alpha.Policy
end

defmodule Envoy.Config.Rbac.V2alpha.RBAC.Action do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field :ALLOW, 0
  field :DENY, 1
end

defmodule Envoy.Config.Rbac.V2alpha.Policy do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          permissions: [Envoy.Config.Rbac.V2alpha.Permission.t()],
          principals: [Envoy.Config.Rbac.V2alpha.Principal.t()]
        }
  defstruct [:permissions, :principals]

  field :permissions, 1, repeated: true, type: Envoy.Config.Rbac.V2alpha.Permission
  field :principals, 2, repeated: true, type: Envoy.Config.Rbac.V2alpha.Principal
end

defmodule Envoy.Config.Rbac.V2alpha.Permission do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          rule: {atom, any}
        }
  defstruct [:rule]

  oneof :rule, 0
  field :and_rules, 1, type: Envoy.Config.Rbac.V2alpha.Permission.Set, oneof: 0
  field :or_rules, 2, type: Envoy.Config.Rbac.V2alpha.Permission.Set, oneof: 0
  field :any, 3, type: :bool, oneof: 0
  field :header, 4, type: Envoy.Api.V2.Route.HeaderMatcher, oneof: 0
  field :destination_ip, 5, type: Envoy.Api.V2.Core.CidrRange, oneof: 0
  field :destination_port, 6, type: :uint32, oneof: 0
end

defmodule Envoy.Config.Rbac.V2alpha.Permission.Set do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          rules: [Envoy.Config.Rbac.V2alpha.Permission.t()]
        }
  defstruct [:rules]

  field :rules, 1, repeated: true, type: Envoy.Config.Rbac.V2alpha.Permission
end

defmodule Envoy.Config.Rbac.V2alpha.Principal do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          identifier: {atom, any}
        }
  defstruct [:identifier]

  oneof :identifier, 0
  field :and_ids, 1, type: Envoy.Config.Rbac.V2alpha.Principal.Set, oneof: 0
  field :or_ids, 2, type: Envoy.Config.Rbac.V2alpha.Principal.Set, oneof: 0
  field :any, 3, type: :bool, oneof: 0
  field :authenticated, 4, type: Envoy.Config.Rbac.V2alpha.Principal.Authenticated, oneof: 0
  field :source_ip, 5, type: Envoy.Api.V2.Core.CidrRange, oneof: 0
  field :header, 6, type: Envoy.Api.V2.Route.HeaderMatcher, oneof: 0
end

defmodule Envoy.Config.Rbac.V2alpha.Principal.Set do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          ids: [Envoy.Config.Rbac.V2alpha.Principal.t()]
        }
  defstruct [:ids]

  field :ids, 1, repeated: true, type: Envoy.Config.Rbac.V2alpha.Principal
end

defmodule Envoy.Config.Rbac.V2alpha.Principal.Authenticated do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t()
        }
  defstruct [:name]

  field :name, 1, type: :string
end
