defmodule Envoy.Config.Filter.Http.Transcoder.V2.GrpcJsonTranscoder do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          descriptor_set: {atom, any},
          services: [String.t()],
          print_options:
            Envoy.Config.Filter.Http.Transcoder.V2.GrpcJsonTranscoder.PrintOptions.t()
        }
  defstruct [:descriptor_set, :services, :print_options]

  oneof :descriptor_set, 0
  field :proto_descriptor, 1, type: :string, oneof: 0
  field :proto_descriptor_bin, 4, type: :bytes, oneof: 0
  field :services, 2, repeated: true, type: :string

  field :print_options, 3,
    type: Envoy.Config.Filter.Http.Transcoder.V2.GrpcJsonTranscoder.PrintOptions
end

defmodule Envoy.Config.Filter.Http.Transcoder.V2.GrpcJsonTranscoder.PrintOptions do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          add_whitespace: boolean,
          always_print_primitive_fields: boolean,
          always_print_enums_as_ints: boolean,
          preserve_proto_field_names: boolean
        }
  defstruct [
    :add_whitespace,
    :always_print_primitive_fields,
    :always_print_enums_as_ints,
    :preserve_proto_field_names
  ]

  field :add_whitespace, 1, type: :bool
  field :always_print_primitive_fields, 2, type: :bool
  field :always_print_enums_as_ints, 3, type: :bool
  field :preserve_proto_field_names, 4, type: :bool
end
