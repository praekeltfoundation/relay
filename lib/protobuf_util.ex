defmodule Relay.ProtobufUtil do
  alias Google.Protobuf.{Struct, NullValue, ListValue, Value}

  defp oneof_actual_vals(props, struct) do
    # Copy/pasta-ed from:
    # https://github.com/tony612/protobuf-elixir/blob/a4389fe18edc70430563d8591aa05bd3dba60adc/lib/protobuf/encoder.ex#L153-L160
    # TODO: Understand this, make it more readable
    Enum.reduce(props.oneof, %{}, fn {field, _}, acc ->
      case Map.get(struct, field) do
        {f, val} -> Map.put(acc, f, val)
        nil -> acc
      end
    end)
  end

  def mkstruct(%{__struct__: mod} = struct) do
    props = mod.__message_props__()
    oneofs = oneof_actual_vals(props, struct)

    fields = props.ordered_tags |> Enum.into(%{}, fn tag ->
      prop = props.field_props[tag]
      val = if prop.oneof, do: oneofs[prop.name_atom], else: Map.get(struct, prop.name_atom)

      {prop.name, struct_value(val)}
    end)
    Struct.new(fields: fields)
  end

  defp struct_value(nil), do:
    Value.new(kind: {:null_value, NullValue.value(:NULL_VALUE)})

  defp struct_value(number) when is_number(number), do:
    Value.new(kind: {:number_value, number})

  defp struct_value(string) when is_binary(string), do:
    Value.new(kind: {:string_value, string})

  defp struct_value(bool) when is_boolean(bool), do:
    Value.new(kind: {:bool_value, bool})

  defp struct_value(%Struct{} = struct), do:
    Value.new(kind: {:struct_value, struct})

  defp struct_value(%_{} = struct), do:
    Value.new(kind: {:struct_value, mkstruct(struct)})

  defp struct_value(list) when is_list(list) do
    values = list |> Enum.map(fn element -> struct_value(element) end)
    Value.new(kind: {:list_value, ListValue.new(values: values)})
  end
end
