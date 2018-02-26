defmodule Relay.Marathon do
  alias Relay.Marathon.{Labels, Networking}

  defmodule App do
    defstruct [:id, :networking_mode, :ports_list, :labels, :version]

    def from_definition(%{"id" => id, "labels" => labels} = app) do
      %App{
        id: id,
        networking_mode: Networking.networking_mode(app),
        ports_list: Networking.ports_list(app),
        labels: labels,
        version: app_config_version(app)
      }
    end

    defp app_config_version(%{"versionInfo" => %{"lastConfigChangeAt" => version}}), do: version

    def port_indices_in_group(%App{ports_list: []}, _group), do: []

    def port_indices_in_group(%App{ports_list: ports_list, labels: labels}, group) do
      0..(length(ports_list) - 1)
      |> Enum.filter(fn port_index -> Labels.marathon_lb_group(labels, port_index) == group end)
    end

    def marathon_lb_vhost(%App{labels: labels}, port_index),
      do: Labels.marathon_lb_vhost(labels, port_index)

    def marathon_lb_redirect_to_https?(%App{labels: labels}, port_index),
      do: Labels.marathon_lb_redirect_to_https?(labels, port_index)

    def marathon_acme_domain(%App{labels: labels}, port_index),
      do: Labels.marathon_acme_domain(labels, port_index)
  end

  defmodule Task do
    defstruct [:id, :app_id, :address, :ports, :version]

    def from_definition(
          %App{id: app_id, networking_mode: networking_mode, ports_list: app_ports_list},
          %{"id" => id, "appId" => app_id, "version" => version} = task
        ) do
      %Task{
        id: id,
        app_id: app_id,
        address: Networking.task_address(networking_mode, task),
        ports: Networking.task_ports(networking_mode, task) || app_ports_list,
        version: version
      }
    end

    def endpoint(%Task{address: address, ports: ports}, port_index),
      do: {address, Enum.at(ports, port_index)}
  end
end
