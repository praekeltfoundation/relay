defmodule Envoy.Api.V2.Filter.Http.IPTagging do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    request_type: integer,
    ip_tags:      [Envoy.Api.V2.Filter.Http.IPTagging.IPTag.t]
  }
  defstruct [:request_type, :ip_tags]

  field :request_type, 1, type: Envoy.Api.V2.Filter.Http.IPTagging.RequestType, enum: true
  field :ip_tags, 2, repeated: true, type: Envoy.Api.V2.Filter.Http.IPTagging.IPTag
end

defmodule Envoy.Api.V2.Filter.Http.IPTagging.IPTag do
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
    ip_tag_name: String.t,
    ip_list:     [Envoy.Api.V2.CidrRange.t]
  }
  defstruct [:ip_tag_name, :ip_list]

  field :ip_tag_name, 1, type: :string
  field :ip_list, 2, repeated: true, type: Envoy.Api.V2.CidrRange
end

defmodule Envoy.Api.V2.Filter.Http.IPTagging.RequestType do
  use Protobuf, enum: true, syntax: :proto3

  field :BOTH, 0
  field :INTERNAL, 1
  field :EXTERNAL, 2
end
