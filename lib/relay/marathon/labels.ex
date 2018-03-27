defmodule Relay.Marathon.Labels do
  @moduledoc """
  Extracts information from Marathon app labels.
  """

  @type labels :: %{optional(String.t) => String.t}

  @doc """
  Get the marathon-lb group for the given port index.
  """
  @spec marathon_lb_group(labels, non_neg_integer) :: String.t | nil
  def marathon_lb_group(app_labels, port_index) do
    default = app_label(app_labels, "GROUP", "HAPROXY")
    port_label(app_labels, "GROUP", port_index, "HAPROXY", default)
  end

  @doc """
  Whether HTTPS redirects should be enabled for the given port index.
  """
  @spec marathon_lb_redirect_to_https?(labels, non_neg_integer) :: boolean
  def marathon_lb_redirect_to_https?(app_labels, port_index),
    do: port_label(app_labels, "REDIRECT_TO_HTTPS", port_index, "HAPROXY") == "true"

  @doc """
  Get the list of marathon-lb vhosts for the given port index.
  """
  @spec marathon_lb_vhost(labels, non_neg_integer) :: [String.t]
  def marathon_lb_vhost(app_labels, port_index),
    do: domains_label(app_labels, "VHOST", port_index, "HAPROXY")

  @doc """
  Get the list of marathon-acme domains for the given port index.
  """
  @spec marathon_acme_domain(labels, non_neg_integer) :: [String.t]
  def marathon_acme_domain(app_labels, port_index),
    do: domains_label(app_labels, "DOMAIN", port_index, "MARATHON_ACME")

  defp domains_label(app_labels, label, port_index, prefix) do
    case port_label(app_labels, label, port_index, prefix) do
      nil -> []
      value -> parse_domains_label(value)
    end
  end

  defp app_label(app_labels, label, prefix, default \\ nil),
    do: get_label(app_labels, [prefix, label], default)

  defp port_label(app_labels, label, port_index, prefix, default \\ nil),
    do: get_label(app_labels, [prefix, port_index, label], default)

  defp get_label(app_labels, parts, default),
    do: Map.get(app_labels, Enum.join(parts, "_"), default)

  @doc false
  @spec parse_domains_label(String.t) :: [String.t]
  def parse_domains_label(label), do: label |> String.replace(",", " ") |> String.split()
end
