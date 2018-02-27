defmodule Envoy.Api.V2.DiscoveryRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          version_info: String.t(),
          node: Envoy.Api.V2.Core.Node.t(),
          resource_names: [String.t()],
          type_url: String.t(),
          response_nonce: String.t(),
          error_detail: Google.Rpc.Status.t()
        }
  defstruct [:version_info, :node, :resource_names, :type_url, :response_nonce, :error_detail]

  field :version_info, 1, type: :string
  field :node, 2, type: Envoy.Api.V2.Core.Node
  field :resource_names, 3, repeated: true, type: :string
  field :type_url, 4, type: :string
  field :response_nonce, 5, type: :string
  field :error_detail, 6, type: Google.Rpc.Status
end

defmodule Envoy.Api.V2.DiscoveryResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          version_info: String.t(),
          resources: [Google.Protobuf.Any.t()],
          canary: boolean,
          type_url: String.t(),
          nonce: String.t()
        }
  defstruct [:version_info, :resources, :canary, :type_url, :nonce]

  field :version_info, 1, type: :string
  field :resources, 2, repeated: true, type: Google.Protobuf.Any
  field :canary, 3, type: :bool
  field :type_url, 4, type: :string
  field :nonce, 5, type: :string
end
