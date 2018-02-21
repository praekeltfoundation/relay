defmodule Relay.Marathon.Labels do
  def marathon_lb_group(app_labels, port_index, options \\ []) do
    prefix = Keyword.get(options, :prefix, "HAPROXY")
    label = Keyword.get(options, :label, "GROUP")

    default = app_label(app_labels, label, prefix, options)

    port_label(app_labels, label, port_index, prefix, Keyword.merge(options, default: default))
  end

  defp app_label(app_labels, label, prefix, options),
    do: get_label(app_labels, [prefix, label], options)

  defp port_label(app_labels, label, port_index, prefix, options),
    do: get_label(app_labels, [prefix, port_index, label], options)

  defp get_label(app_labels, parts, options) do
    sep = Keyword.get(options, :sep, "_")
    default = Keyword.get(options, :default)

    Map.get(app_labels, Enum.join(parts, sep), default)
  end


  def parse_domains_label(label), do: label |> String.replace(",", " ") |> String.split()
end
