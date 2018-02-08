defmodule Relay.ProtobufUtil do
  alias Google.Protobuf.{Struct, NullValue, ListValue, Value}

  def mkstruct(%_{} = struct) do
    fields = Map.from_struct(struct)
      |> Enum.into(%{}, fn {k, v} -> {Atom.to_string(k), struct_value(v)} end)
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
