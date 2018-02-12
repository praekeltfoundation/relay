defmodule Relay.ProtobufUtilTest do
  use ExUnit.Case, async: true

  alias Relay.ProtobufUtil
  alias Google.Protobuf.{Any, ListValue, NullValue, Struct, Value}

  test "null type packed" do
    defmodule NullType do
      use Protobuf, syntax: :proto3

      @type t :: %__MODULE__{
        foo: Struct.t
      }
      defstruct [:foo]

      field :foo, 1, type: Struct
    end

    proto = NullType.new() # Don't provide foo
    struct = ProtobufUtil.mkstruct(proto)

    assert struct == %Struct{
      fields: %{
        "foo" => %Value{kind: {:null_value, NullValue.value(:NULL_VALUE)}},
      }
    }
  end

  test "basic types packed" do
    defmodule BasicTypes do
      use Protobuf, syntax: :proto3

      @type t :: %__MODULE__{
        foo: integer,
        bar: boolean,
        baz: String.t
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
        "baz" => %Value{kind: {:string_value, "abc"}},
      }
    }
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
        bar: NestedType.t
      }
      defstruct [:bar]

      field :bar, 1, type: NestedType
    end

    proto = NestingType.new(bar: NestedType.new(foo: 123))
    struct = ProtobufUtil.mkstruct(proto)

    assert struct == %Struct{
      fields: %{
        "bar" => %Value{kind: {:struct_value, %Struct{
          fields: %{
            "foo" => %Value{kind: {:number_value, 123}}},
          }}},
      }
    }
  end

  test "nested struct packed as struct" do
    defmodule StructType do
      use Protobuf, syntax: :proto3

      @type t :: %__MODULE__{
        foo: Struct.t
      }
      defstruct [:foo]

      field :foo, 1, type: Struct
    end

    proto = StructType.new(
      foo: Struct.new(fields: %{"bar" => Value.new(kind: {:string_value, "abc"})}))
    struct = ProtobufUtil.mkstruct(proto)

    assert struct == %Struct{
      fields: %{
        "foo" => %Value{kind: {:struct_value, %Struct{
          fields: %{
            "bar" => %Value{kind: {:string_value, "abc"}}},
          }}},
      }
    }
  end

  test "list values packed" do
    defmodule ListType do
      use Protobuf, syntax: :proto3

      @type t :: %__MODULE__{
        foo: [String.t],
      }
      defstruct [:foo]

      field :foo, 1, repeated: true, type: :string
    end

    proto = ListType.new(foo: ["abc", "def"])
    struct = ProtobufUtil.mkstruct(proto)

    assert struct == %Struct{
      fields: %{
        "foo" => %Value{kind: {:list_value, %ListValue{values: [
          %Value{kind: {:string_value, "abc"}},
          %Value{kind: {:string_value, "def"}},
        ]}}},
      }
    }
  end

  test "oneof values packed" do
    defmodule OneofType do
      use Protobuf, syntax: :proto3

      @type t :: %__MODULE__{
        foobar: {atom, any},
        baz: String.t
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
        "foo" => %Value{kind: {:null_value, NullValue.value(:NULL_VALUE)}},
        "bar" => %Value{kind: {:bool_value, true}},
        "baz" => %Value{kind: {:string_value, "def"}},
      }
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

    assert_raise Protobuf.InvalidError, "Relay.ProtobufUtilTest.ValidatedType#foo is invalid!", fn ->
      ProtobufUtil.mkstruct(proto)
    end
  end

  test "Any encodes a type" do
    proto = Value.new(kind: {:string_value, "abcdef"})
    any = ProtobufUtil.mkany("example.com/mytype", proto)

    assert %Any{type_url: "example.com/mytype", value: value} = any
    assert Value.decode(value) == proto
  end
end
