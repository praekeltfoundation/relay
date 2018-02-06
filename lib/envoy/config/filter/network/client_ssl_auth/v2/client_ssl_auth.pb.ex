defmodule Envoy.Config.Filter.Network.ClientSslAuth.V2.ClientSSLAuth do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    auth_api_cluster: String.t,
    stat_prefix:      String.t,
    refresh_delay:    Google.Protobuf.Duration.t,
    ip_white_list:    [Envoy.Api.V2.Core.CidrRange.t]
  }
  defstruct [:auth_api_cluster, :stat_prefix, :refresh_delay, :ip_white_list]

  field :auth_api_cluster, 1, type: :string
  field :stat_prefix, 2, type: :string
  field :refresh_delay, 3, type: Google.Protobuf.Duration
  field :ip_white_list, 4, repeated: true, type: Envoy.Api.V2.Core.CidrRange
end
