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
        %{"id" => id, "appId" => app_id} = task
      ) do
    %__MODULE__{
      id: id,
      app_id: app_id,
      address: Networking.task_address(app.networking_mode, task),
      ports: Networking.task_ports(app.networking_mode, task) || app.ports_list,
      version: version(task)
    }
  end

  @spec from_event(App.t, map) :: t
  def from_event(
        %App{id: app_id} = app,
        %{"eventType" => "status_update_event", "taskId" => id, "appId" => app_id} = event
      ) do
    %__MODULE__{
      id: id,
      app_id: app_id,
      address: Networking.task_address(app.networking_mode, event),
      ports: Networking.task_ports(app.networking_mode, event) || app.ports_list,
      version: version(event)
    }
  end

  @spec version(map) :: String.t
  defp version(task) do
    # Get the latest version information for the task.
    case task do
      # `startedAt` could be nil if task hasn't started
      %{"startedAt" => version} when is_binary(version) -> version
      # Don't know when `stagedAt` could be nil, but apparently tasks don't
      # necessarily have to go through a staging state:
      # http://mesosphere.github.io/marathon/docs/task-handling.html
      %{"stagedAt" => version} when is_binary(version) -> version
      # Fall back to the `version` field (which seems to match the app `version`
      # field). Events currently only have this version field.
      %{"version" => version} -> version
    end
  end

  @spec endpoint(t, non_neg_integer) :: {String.t, Networking.port_number}
  def endpoint(%__MODULE__{address: address, ports: ports}, port_index),
    do: {address, Enum.at(ports, port_index)}
end
