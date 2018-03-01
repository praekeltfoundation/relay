defmodule Relay.Marathon.Task do
  alias Relay.Marathon.{App, Networking}

  defstruct [:id, :app_id, :address, :ports, :version]

  def from_definition(
        %App{id: app_id} = app,
        %{"id" => id, "appId" => app_id, "version" => version} = task
      ) do
    %__MODULE__{
      id: id,
      app_id: app_id,
      address: Networking.task_address(app.networking_mode, task),
      ports: Networking.task_ports(app.networking_mode, task) || app.ports_list,
      version: version
    }
  end

  def endpoint(%__MODULE__{address: address, ports: ports}, port_index),
    do: {address, Enum.at(ports, port_index)}
end
