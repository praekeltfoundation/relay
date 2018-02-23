defmodule Relay.Marathon do
  alias Relay.Marathon.Networking

  defmodule App do
    defstruct [:id, :networking_mode, :ports_list, :labels, :version]

    def from_definition(%{"id" => id, "labels" => labels} = app) do
      networking_mode = Networking.networking_mode(app)
      %App{
        id: id,
        networking_mode: networking_mode,
        ports_list: Networking.ports_list(networking_mode, app),
        labels: labels,
        version: app_config_version(app)
      }
    end

    defp app_config_version(%{"versionInfo" => %{"lastConfigChangeAt" => version}}), do: version
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
        ports: Networking.task_ports(networking_mode, task, app_ports_list),
        version: version
      }
    end
  end
end
