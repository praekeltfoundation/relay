defmodule Relay.ProtobufUtilTest do
  use ExUnit.Case, async: true

  alias Relay.ProtobufUtil
  alias Google.Protobuf.{Any, BoolValue, ListValue, Struct, Value}

  describe "mkstruct/1" do
    test "basic types packed" do
      defmodule BasicTypes do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                foo: integer,
                bar: boolean,
                baz: String.t()
              }
        defstruct [:foo, :bar, :baz]

        field :foo, 1, type: :uint32
        field :bar, 2, type: :bool
        field :baz, 3, type: :string
      end

      proto = BasicTypes.new(foo: 123, bar: true, baz: "abc")
      struct = ProtobufUtil.mkstruct(proto)

      assert struct == %Struct{
               fields: %{
                 "foo" => %Value{kind: {:number_value, 123}},
                 "bar" => %Value{kind: {:bool_value, true}},
                 "baz" => %Value{kind: {:string_value, "abc"}}
               }
             }
    end

    test "unset fields not packed" do
      defmodule UnsetTypes do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                bar: boolean,
                baz: Struct.t()
              }
        defstruct [:bar, :baz]

        field :bar, 1, type: :bool
        field :baz, 2, type: Struct
      end

      proto = UnsetTypes.new()
      struct = ProtobufUtil.mkstruct(proto)

      assert struct == %Struct{fields: %{}}
    end

    test "nested proto packed as struct" do
      defmodule NestedType do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                foo: integer
              }
        defstruct [:foo]

        field :foo, 1, type: :uint32
      end

      defmodule NestingType do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                bar: NestedType.t()
              }
        defstruct [:bar]

        field :bar, 1, type: NestedType
      end

      proto = NestingType.new(bar: NestedType.new(foo: 123))
      struct = ProtobufUtil.mkstruct(proto)

      assert struct == %Struct{
               fields: %{
                 "bar" => %Value{
                   kind:
                     {:struct_value,
                      %Struct{
                        fields: %{"foo" => %Value{kind: {:number_value, 123}}}
                      }}
                 }
               }
             }
    end

    test "nested struct packed as struct" do
      defmodule StructType do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                foo: Struct.t()
              }
        defstruct [:foo]

        field :foo, 1, type: Struct
      end

      proto =
        StructType.new(
          foo: Struct.new(fields: %{"bar" => Value.new(kind: {:string_value, "abc"})})
        )

      struct = ProtobufUtil.mkstruct(proto)

      assert struct == %Struct{
               fields: %{
                 "foo" => %Value{
                   kind:
                     {:struct_value,
                      %Struct{
                        fields: %{"bar" => %Value{kind: {:string_value, "abc"}}}
                      }}
                 }
               }
             }
    end

    test "list values packed" do
      defmodule ListType do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                foo: [String.t()]
              }
        defstruct [:foo]

        field :foo, 1, repeated: true, type: :string
      end

      proto = ListType.new(foo: ["abc", "def"])
      struct = ProtobufUtil.mkstruct(proto)

      assert struct == %Struct{
               fields: %{
                 "foo" => %Value{
                   kind:
                     {:list_value,
                      %ListValue{
                        values: [
                          %Value{kind: {:string_value, "abc"}},
                          %Value{kind: {:string_value, "def"}}
                        ]
                      }}
                 }
               }
             }
    end

    test "oneof values packed" do
      defmodule OneofType do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                foobar: {atom, any},
                baz: String.t()
              }
        defstruct [:foobar, :baz]

        oneof :foobar, 0
        field :foo, 1, type: :uint32, oneof: 0
        field :bar, 2, type: :bool, oneof: 0
        field :baz, 3, type: :string
      end

      proto = OneofType.new(foobar: {:bar, true}, baz: "def")
      struct = ProtobufUtil.mkstruct(proto)

      assert struct == %Struct{
               fields: %{
                 "bar" => %Value{kind: {:bool_value, true}},
                 "baz" => %Value{kind: {:string_value, "def"}}
               }
             }
    end

    test "unset oneof values not packed" do
      defmodule UnsetOneofType do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                foobar: {atom, any},
                baz: String.t()
              }
        defstruct [:foobar, :baz]

        oneof :foobar, 0
        field :foo, 1, type: :uint32, oneof: 0
        field :bar, 2, type: :bool, oneof: 0
        field :baz, 3, type: :string
      end

      proto = UnsetOneofType.new(baz: "def")
      struct = ProtobufUtil.mkstruct(proto)

      assert struct == %Struct{
               fields: %{"baz" => %Value{kind: {:string_value, "def"}}}
             }
    end

    test "protobufs validated before packing" do
      defmodule ValidatedType do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                foo: integer
              }
        defstruct [:foo]

        field :foo, 1, type: :uint32
      end

      proto = ValidatedType.new(foo: "ghi")

      assert_raise Protobuf.InvalidError,
                   "Relay.ProtobufUtilTest.ValidatedType#foo is invalid!",
                   fn ->
                     ProtobufUtil.mkstruct(proto)
                   end
    end

    test "structs serialize and deserialize to the same thing" do
      defmodule SerializedType do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                foo: String.t(),
                bar: String.t()
              }
        defstruct [:foo, :bar]

        field :foo, 1, type: :string
        field :bar, 2, type: :string
      end

      proto = SerializedType.new(foo: "baz")
      struct = ProtobufUtil.mkstruct(proto)

      serialized = Struct.encode(struct)
      assert Struct.decode(serialized) == struct
    end

    test "oneof structs serialize and deserialize to the same thing" do
      defmodule OneofSerializedType do
        use Protobuf, syntax: :proto3

        @type t :: %__MODULE__{
                foobar: {atom, any},
                baz: String.t()
              }
        defstruct [:foobar, :baz]

        oneof :foobar, 0
        field :foo, 1, type: :uint32, oneof: 0
        field :bar, 2, type: :bool, oneof: 0
        field :baz, 3, type: :string
      end

      proto = OneofSerializedType.new(foobar: {:bar, true}, baz: "def")
      struct = ProtobufUtil.mkstruct(proto)
      serialized = Struct.encode(struct)
      assert Struct.decode(serialized) == struct
    end
  end

  describe "mkany/2" do
    test "Any encodes a type" do
      proto = Value.new(kind: {:string_value, "abcdef"})
      any = ProtobufUtil.mkany("example.com/mytype", proto)

      assert %Any{type_url: "example.com/mytype", value: value} = any
      assert Value.decode(value) == proto
    end
  end

  describe "mkvalue/1" do
    test "nil" do
      assert ProtobufUtil.mkvalue(nil) == nil
    end

    test "booleans" do
      assert ProtobufUtil.mkvalue(true) == BoolValue.new(value: true)
      assert ProtobufUtil.mkvalue(false) == BoolValue.new(value: false)
    end
  end
end
