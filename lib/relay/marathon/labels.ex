defmodule Relay.Marathon.Labels do
  def marathon_lb_group(app_labels, port_index, options \\ []) do
    prefix = Keyword.get(options, :prefix, "HAPROXY")
    label = Keyword.get(options, :label, "GROUP")

    default = app_label(app_labels, label, prefix, options)

    port_label(app_labels, label, port_index, prefix, Keyword.merge(options, default: default))
  end

  def marathon_lb_redirect_to_https?(app_labels, port_index, options \\ []),
    do:
      port_label(
        app_labels,
        Keyword.get(options, :label, "REDIRECT_TO_HTTPS"),
        port_index,
        Keyword.get(options, :prefix, "HAPROXY"),
        options
      ) in Keyword.get(options, :true_values, ["true"])

  def marathon_lb_vhost(app_labels, port_index, options \\ []),
    do:
      domains_label(
        app_labels,
        Keyword.get(options, :label, "VHOST"),
        port_index,
        Keyword.get(options, :prefix, "HAPROXY"),
        options
      )

  def marathon_acme_domain(app_labels, port_index, options \\ []),
    do:
      domains_label(
        app_labels,
        Keyword.get(options, :label, "DOMAIN"),
        port_index,
        Keyword.get(options, :prefix, "MARATHON_ACME"),
        options
      )

  defp domains_label(app_labels, label, port_index, prefix, options) do
    case port_label(app_labels, label, port_index, prefix, options) do
      nil -> []
      value -> parse_domains_label(value)
    end
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
