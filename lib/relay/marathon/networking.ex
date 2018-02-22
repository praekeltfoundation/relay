defmodule Relay.Marathon.Networking do
  @moduledoc """
  Utilities for working with Marathon app JSON across different versions of
  Marathon.
  """

  @doc """
  Get the number of ports that this app exposes.
  """
  def get_number_of_ports(app), do: ports_list(networking_mode(app), app) |> length()

  def get_task_ip(app, task) do
    case networking_mode(app) do
      :container -> task_ip_addresses(task)
      _ -> task_host_address(task)
    end
  end

  def get_task_ports(app, task), do: ports_list(networking_mode(app), app, task)

  defp ports_list(networking_mode, app, task)
      when networking_mode in [:host, :"container/bridge"] do
    case task do
      %{"ports" => ports} -> ports
      _ -> ports_list(networking_mode, app)
    end
  end

  defp ports_list(:container, app, _task), do: ports_list(:container, app)

  defp ports_list(:host, app),
    do: port_definitions_ports(app)

  defp ports_list(:"container/bridge", app) do
    case port_definitions_ports(app) do
      nil -> port_mappings_ports(app)
      definitions -> definitions
    end
  end

  defp ports_list(:container, app) do
    case ip_address_discovery_ports(app) do
      nil -> port_mappings_ports(app)
      ports -> ports
    end
  end

  defp task_ip_addresses(%{"ipAddresses" => [%{"ipAddress" => ipAddress} | _ipAddresses]})
      when is_binary(ipAddress),
    do: ipAddress

  # No address allocated yet
  defp task_ip_addresses(_task), do: nil

  defp task_host_address(%{"host" => host}), do: gethostbyname(host)

  defp task_host_address(_task), do: nil

  defp gethostbyname(hostname) do
    # TODO: Do we need to cache these results somehow? marathon-lb does (but not
    # very well)
    # This is fine if hostname is an IP: it just returns the same IP
    case :inet.gethostbyname(String.to_charlist(hostname)) do
      {:ok, {:hostent, _hostname, _, :inet, 4, [address | _addresses]}} ->
        Tuple.to_list(address) |> Enum.join(".")
      # TODO: Support IPv6

      {:error, _reason} -> nil
    end
  end

  # Marathon 1.5+: there is a `networks` field
  defp networking_mode(%{"networks" => [network | _networks]}),
    do: network |> Map.get("mode", "container") |> String.to_atom()

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

  defp port_definitions_ports(app) do
    case port_definitions(app) do
      nil -> nil
      definitions ->
        Enum.map(definitions, fn definition ->
          case definition do
            %{"port" => port} -> port
            _ -> nil
          end
        end)
    end
  end

  defp port_definitions(%{"portDefinitions" => port_definitions}), do: port_definitions

  # Very old Marathon without portDefinitions
  defp port_definitions(%{"ports" => ports}), do: ports

  defp port_definitions(_app), do: nil

  defp port_mappings_ports(app) do
    case container_port_mappings(app) do
      nil -> nil
      mappings ->
        Enum.map(mappings, fn mapping ->
          case mapping do
            %{"containerPort" => port} -> port
            _ -> nil
          end
        end)
    end
  end

  # Marathon 1.5+: container.portMappings field
  defp container_port_mappings(%{"container" => %{"portMappings" => port_mappings}}), do:
    port_mappings

  # Older Marathon: container.docker.portMappings field
  defp container_port_mappings(
      %{"container" => %{"docker" => %{"portMappings" => port_mappings}}}), do:
    port_mappings

  defp container_port_mappings(_app), do: nil

  # Marathon 1.5+: the ipAddress field is missing
  # Marathon <1.5: the ipAddress field can be present, but can still have an
  # empty ports list :-/
  defp ip_address_discovery_ports(
      %{"ipAddress" => %{"discovery" => %{"ports" => ports}}}) when length(ports) > 0, do:
    ports

  defp ip_address_discovery_ports(_app), do: nil
end
