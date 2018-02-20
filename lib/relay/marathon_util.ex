defmodule Relay.MarathonUtil do
  @moduledoc """
  Utilities for working with Marathon app JSON across different versions of
  Marathon.
  """

  @doc """
  Get the number of ports that this app exposes.
  """
  def get_number_of_ports(app) do
    ports_list = case networking_mode(app) do
      :host -> port_definitions(app)

      :"container/bridge" ->
        case port_definitions(app) do
          nil -> container_port_mappings(app)
          definitions -> definitions
        end

      :container ->
        case ip_address_discovery_ports(app) do
          nil -> container_port_mappings(app)
          ports -> ports
        end
    end

    length(ports_list)
  end

  # Marathon 1.5+: there is a `networks` field
  defp networking_mode(%{"networks" => networks}), do:
    hd(networks) |> Map.get("mode", "container") |> String.to_atom()

  # Pre-Marathon 1.5 Docker container networking mode
  defp networking_mode(%{"container" => %{"docker" => %{"network" => network}}}) do
    case network do
      "USER"   -> :container
      "BRIDGE" -> :"container/bridge"
      "HOST"   -> :host
    end
  end

  # Legacy IP-per-task networking mode
  defp networking_mode(%{"ipAddress" => ip_address}) when not is_nil(ip_address), do:
    :container

  # Default to host networking mode
  defp networking_mode(_app), do: :host

  defp port_definitions(%{"portDefinitions" => port_definitions}), do: port_definitions

  # Very old Marathon without portDefinitions
  defp port_definitions(%{"ports" => ports}), do: ports

  defp port_definitions(_app), do: nil

  # Marathon 1.5+: container.portMappings field
  defp container_port_mappings(%{"container" => %{"portMappings" => port_mappings}}), do:
    port_mappings

  # Older Marathon: container.docker.portMappings field
  defp container_port_mappings(
      %{"container" => %{"docker" => %{"portMappings" => port_mappings}}}), do:
    port_mappings

  # Marathon 1.5+: the ipAddress field is missing
  # Marathon <1.5: the ipAddress field can be present, but can still have an
  # empty ports list :-/
  defp ip_address_discovery_ports(
      %{"ipAddress" => %{"discovery" => %{"ports" => ports}}}) when length(ports) > 0, do:
    ports

  defp ip_address_discovery_ports(_app), do: nil

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
