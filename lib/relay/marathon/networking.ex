defmodule Relay.Marathon.Networking do
  @moduledoc """
  Utilities for working with Marathon app JSON across different versions of
  Marathon.
  """

  @doc """
  Get the number of ports that this app exposes.
  """
  def get_number_of_ports(app), do: networking_mode(app) |> ports_list(app) |> length()

  def get_task_address(app, task), do: networking_mode(app) |> task_address(task)

  def get_task_ports(app, task), do: networking_mode(app) |> ports_list(app, task)

  defp task_address(:container, task), do: task_ip_address(task)

  defp task_address(_networking_mode, task), do: task_host(task)

  defp ports_list(:host, _app, %{"ports" => ports} = _task), do: ports

  defp ports_list(:"container/bridge", _app, %{"ports" => ports}), do: ports

  defp ports_list(:container, app, _task), do: ports_list(:container, app)

  defp ports_list(:host, app),
    do: port_definitions_ports(app)

  defp ports_list(:"container/bridge", app),
    do: port_definitions_ports(app) || port_mappings_ports(app)

  defp ports_list(:container, app),
    do: ip_address_discovery_ports(app) || port_mappings_ports(app)

  defp task_ip_address(%{"ipAddresses" => [%{"ipAddress" => ip_address} | _]})
      when is_binary(ip_address),
    do: ip_address

  # No address allocated yet
  defp task_ip_address(_task), do: nil

  defp task_host(%{"host" => host}), do: host

  defp task_host(_task), do: nil

  # Marathon 1.5+: there is a `networks` field
  # Networking modes can't be mixed so using the first one is fine
  defp networking_mode(%{"networks" => [network | _]}),
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
      definitions -> Enum.map(definitions, fn %{"port" => port} -> port end)
    end
  end

  defp port_definitions(%{"portDefinitions" => port_definitions}), do: port_definitions

  defp port_definitions(_app), do: nil

  defp port_mappings_ports(app) do
    case container_port_mappings(app) do
      nil -> nil
      mappings -> Enum.map(mappings, fn %{"containerPort" => port} -> port end)
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
