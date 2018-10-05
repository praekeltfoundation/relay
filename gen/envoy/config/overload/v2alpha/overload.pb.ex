defmodule Envoy.Config.Overload.V2alpha.ResourceMonitor do
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

defmodule Envoy.Config.Overload.V2alpha.ThresholdTrigger do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          value: float
        }
  defstruct [:value]

  field :value, 1, type: :double
end

defmodule Envoy.Config.Overload.V2alpha.Trigger do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          trigger_oneof: {atom, any},
          name: String.t()
        }
  defstruct [:trigger_oneof, :name]

  oneof :trigger_oneof, 0
  field :name, 1, type: :string
  field :threshold, 2, type: Envoy.Config.Overload.V2alpha.ThresholdTrigger, oneof: 0
end

defmodule Envoy.Config.Overload.V2alpha.OverloadAction do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          triggers: [Envoy.Config.Overload.V2alpha.Trigger.t()]
        }
  defstruct [:name, :triggers]

  field :name, 1, type: :string
  field :triggers, 2, repeated: true, type: Envoy.Config.Overload.V2alpha.Trigger
end

defmodule Envoy.Config.Overload.V2alpha.OverloadManager do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          refresh_interval: Google.Protobuf.Duration.t(),
          resource_monitors: [Envoy.Config.Overload.V2alpha.ResourceMonitor.t()],
          actions: [Envoy.Config.Overload.V2alpha.OverloadAction.t()]
        }
  defstruct [:refresh_interval, :resource_monitors, :actions]

  field :refresh_interval, 1, type: Google.Protobuf.Duration
  field :resource_monitors, 2, repeated: true, type: Envoy.Config.Overload.V2alpha.ResourceMonitor
  field :actions, 3, repeated: true, type: Envoy.Config.Overload.V2alpha.OverloadAction
end
