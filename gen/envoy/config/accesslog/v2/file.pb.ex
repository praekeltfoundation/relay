defmodule Envoy.Config.Accesslog.V2.FileAccessLog do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          path: String.t(),
          format: String.t()
        }
  defstruct [:path, :format]

  field :path, 1, type: :string
  field :format, 2, type: :string
end
