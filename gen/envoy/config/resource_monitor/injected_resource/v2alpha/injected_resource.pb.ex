defmodule Envoy.Config.ResourceMonitor.InjectedResource.V2alpha.InjectedResourceConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filename: String.t()
        }
  defstruct [:filename]

  field :filename, 1, type: :string
end
