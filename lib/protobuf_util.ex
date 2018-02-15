defmodule Relay.ProtobufUtil do
  @moduledoc """
  Utility functions for working with Protobuf structs, primarily when using the
  Google.Protobuf types.
  """

  alias Google.Protobuf.{Any, Struct, ListValue, Value}

  defp oneof_actual_vals(message_props, struct) do
    # Copy/pasta-ed from:
    # https://github.com/tony612/protobuf-elixir/blob/a4389fe18edc70430563d8591aa05bd3dba60adc/lib/protobuf/encoder.ex#L153-L160
    # TODO: Make this more readable
    Enum.reduce(message_props.oneof, %{}, fn {field, _}, acc ->
      case Map.get(struct, field) do
        {f, val} -> Map.put(acc, f, val)
        nil -> acc
      end
    end)
  end

  @doc """
  Pack a Protobuf struct into a Google.Protobuf.Struct type.

  This packing assumes that the Struct will be unpacked into a Protobuf type on
  the "other side of the wire", rather than a language-specific type. Because of
  this, Protobuf fields with default or null values will not be included in the
  produced Struct.

  The Protobuf struct will be validated before packing.
  """
  def mkstruct(%mod{} = struct) do
    Protobuf.Validator.validate!(struct)

    message_props = mod.__message_props__()
    oneofs = oneof_actual_vals(message_props, struct)

    fields = message_props.field_props |> Enum.reduce(%{}, fn {_, field_prop}, acc ->
      source = if field_prop.oneof, do: oneofs, else: struct
      value = Map.get(source, field_prop.name_atom)

      default = Protobuf.Builder.field_default(message_props.syntax, field_prop)
      case value do
        nil      -> acc
        ^default -> acc
        _        -> Map.put(acc, field_prop.name, struct_value(value))
      end
    end)
    Struct.new(fields: fields)
  end

  defp struct_value(number) when is_number(number), do: value(:number_value, number)

  defp struct_value(string) when is_binary(string), do: value(:string_value, string)

  defp struct_value(bool) when is_boolean(bool), do: value(:bool_value, bool)

  defp struct_value(%Struct{} = struct), do: value(:struct_value, struct)

  defp struct_value(%_{} = struct), do: value(:struct_value, mkstruct(struct))

  defp struct_value(list) when is_list(list) do
    values = list |> Enum.map(fn element -> struct_value(element) end)
    value(:list_value, ListValue.new(values: values))
  end

  defp value(kind, val), do: Value.new(kind: {kind, val})

  @doc """
  Encode a Protobuf struct into a Google.Protobuf.Any type.
  """
  def mkany(type_url, %mod{} = value), do:
    Any.new(type_url: type_url, value: mod.encode(value))
end
