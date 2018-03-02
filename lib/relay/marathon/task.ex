defmodule Relay.Marathon.Task do
  alias Relay.Marathon.{App, Networking}

  defstruct [:id, :app_id, :address, :ports, :version]
  @type t :: %__MODULE__{
    id: String.t,
    app_id: String.t,
    address: String.t,
    ports: [Networking.port_number],
    version: String.t
  }

  @spec from_definition(App.t, map) :: t
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

  @spec endpoint(t, non_neg_integer) :: {String.t, Networking.port_number}
  def endpoint(%__MODULE__{address: address, ports: ports}, port_index),
    do: {address, Enum.at(ports, port_index)}
end
