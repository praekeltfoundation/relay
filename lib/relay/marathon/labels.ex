defmodule Relay.Marathon.Labels do
  def app_label(app_labels, label, options \\ []),
    do: get_label(app_labels, [label], options)

  def port_label(app_labels, label, port_index, options \\ []),
    do: get_label(app_labels, [port_index, label], options)

  defp get_label(app_labels, parts, options) do
    prefix = Keyword.get(options, :prefix, "HAPROXY")
    sep = Keyword.get(options, :sep, "_")
    default = Keyword.get(options, :default)

    Map.get(app_labels, Enum.join([prefix | parts], sep), default)
  end

  def port_in_group?(app_labels, port_index, group, options \\ []) do
    label = Keyword.get(options, :label, "GROUP")
    default = app_label(app_labels, label, options)

    port_label(app_labels, label, port_index, Keyword.merge(options, default: default)) == group
  end

  def parse_domains_label(label), do: label |> String.replace(",", " ") |> String.split()
end
