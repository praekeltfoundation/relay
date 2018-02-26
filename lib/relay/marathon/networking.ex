defmodule Relay.Marathon.Networking do
  @moduledoc """
  Utilities for working with Marathon app JSON across different versions of
  Marathon.
  """

  # Networking mode

  @doc """
  Get the Marathon 1.5-equivalent networking mode for an app across different
  Marathon versions. Returns one of :container, :"container/bridge", or :host.
  """
  # Marathon 1.5+: there is a `networks` field
  # Networking modes can't be mixed so using the first one is fine
  def networking_mode(%{"networks" => [network | _]} = _app),
    do: network |> Map.get("mode", "container") |> String.to_atom()

  # Pre-Marathon 1.5 Docker container networking mode
  def networking_mode(%{"container" => %{"docker" => %{"network" => network}}}) do
    case network do
      "USER"   -> :container
      "BRIDGE" -> :"container/bridge"
      "HOST"   -> :host
    end
  end

  # Legacy IP-per-task networking mode
  def networking_mode(%{"ipAddress" => ip_address}) when not is_nil(ip_address), do:
    :container

  # Default to host networking mode
  def networking_mode(_app), do: :host

  # Ports list

  def ports_list(app), do: networking_mode(app) |> ports_list(app)

  defp ports_list(:host, app), do: port_definitions_ports(app)

  defp ports_list(:"container/bridge", app),
    do: port_definitions_ports(app) || port_mappings_ports(app)

  defp ports_list(:container, app),
    do: ip_address_discovery_ports(app) || port_mappings_ports(app)

  defp port_definitions_ports(%{"portDefinitions" => port_definitions}),
    do: port_definitions |> Enum.map(fn %{"port" => port} -> port end)

  defp port_definitions_ports(_app), do: nil

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
    ports |> Enum.map(fn %{"number" => number} -> number end)

  defp ip_address_discovery_ports(_app), do: nil

  # Task address

  def task_address(:container, task), do: task_ip_address(task)

  def task_address(_networking_mode, task), do: task_host(task)

  defp task_ip_address(%{"ipAddresses" => [%{"ipAddress" => ip_address} | _]})
      when is_binary(ip_address),
    do: ip_address

  # No address allocated yet
  defp task_ip_address(_task), do: nil

  defp task_host(%{"host" => host}), do: host

  defp task_host(_task), do: nil

  # Task ports

  def task_ports(:host = _networking_mode, %{"ports" => ports} = _task), do: ports

  def task_ports(:"container/bridge", %{"ports" => ports}), do: ports

  def task_ports(:container, _task), do: nil
end
