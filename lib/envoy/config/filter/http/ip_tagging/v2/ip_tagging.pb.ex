defmodule Envoy.Config.Filter.Http.IpTagging.V2.IPTagging do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    request_type: integer,
    ip_tags:      [Envoy.Config.Filter.Http.IpTagging.V2.IPTagging.IPTag.t]
  }
  defstruct [:request_type, :ip_tags]

  field :request_type, 1, type: Envoy.Config.Filter.Http.IpTagging.V2.IPTagging.RequestType, enum: true
  field :ip_tags, 4, repeated: true, type: Envoy.Config.Filter.Http.IpTagging.V2.IPTagging.IPTag
end

defmodule Envoy.Config.Filter.Http.IpTagging.V2.IPTagging.IPTag do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    ip_tag_name: String.t,
    ip_list:     [Envoy.Api.V2.Core.CidrRange.t]
  }
  defstruct [:ip_tag_name, :ip_list]

  field :ip_tag_name, 1, type: :string
  field :ip_list, 2, repeated: true, type: Envoy.Api.V2.Core.CidrRange
end

defmodule Envoy.Config.Filter.Http.IpTagging.V2.IPTagging.RequestType do
  use Protobuf, enum: true, syntax: :proto3

  field :BOTH, 0
  field :INTERNAL, 1
  field :EXTERNAL, 2
end
