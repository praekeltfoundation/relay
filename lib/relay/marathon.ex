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
        version: config_version(app)
      }
    end

    defp config_version(%{"versionInfo" => %{"lastConfigChangeAt" => version}}), do: version

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
          %App{id: app_id} = app,
          %{"id" => id, "appId" => app_id, "version" => version} = task
        ) do
      %Task{
        id: id,
        app_id: app_id,
        address: Networking.task_address(app.networking_mode, task),
        ports: Networking.task_ports(app.networking_mode, task) || app.ports_list,
        version: version
      }
    end

    def endpoint(%Task{address: address, ports: ports}, port_index),
      do: {address, Enum.at(ports, port_index)}
  end

  defmodule State do
    defstruct apps: %{}, tasks: %{}, app_tasks: %{}

    @doc """
    Add an app to `state`. The app is only added if its version is newer than
    the existing app.

    Returns a tuple where the first element is the version of the app already in
    the state (or `nil` if there was no app with the ID) and the second element
    is the new state.
    """
    def put_app(%State{apps: apps} = state, %App{id: id, version: version} = app) do
      case Map.get(apps, id) do
        # App is newer than existing app, update the app
        %App{version: existing_version} when version > existing_version ->
          {existing_version, update_app!(state, app)}

        # App is the same or older than existing app, do nothing
        %App{version: existing_version} ->
          {existing_version, state}

        # No existing app with this ID, add this one
        nil ->
          {nil, add_app(state, app)}
      end
    end

    defp add_app(%State{apps: apps, app_tasks: app_tasks} = state, %App{id: id} = app),
      do: %{state | apps: Map.put(apps, id, app), app_tasks: Map.put(app_tasks, id, MapSet.new())}

    defp update_app!(%State{apps: apps} = state, %App{id: id} = app),
      do: %{state | apps: Map.replace!(apps, id, app)}

    @doc """
    Delete an app from the state. All tasks for the app will also be removed.

    Returns the new state. If the app is not in `state`, returns `state`
    unchanged.
    """
    def delete_app(%State{apps: apps, tasks: tasks, app_tasks: app_tasks} = state, %App{id: id}) do
      case Map.pop(apps, id) do
        {%App{}, new_apps} ->
          {tasks_for_app, new_app_tasks} = Map.pop(app_tasks, id)
          new_tasks = Map.drop(tasks, tasks_for_app)

          %{state | apps: new_apps, tasks: new_tasks, app_tasks: new_app_tasks}

        {nil, _} ->
          state
      end
    end

    @doc """
    Add a task to `state`. The task is only added if its version is newer than
    the existing task.

    Returns a tuple where the first element is the version of the task already
    in the state (or `nil` if there was no task with the ID) and the second
    element is the new state.

    Raises a `KeyError` if the app that the task belongs to is not in `state`.
    """
    def put_task!(%State{tasks: tasks} = state, %Task{id: id, version: version} = task) do
      case Map.get(tasks, id) do
        # Task is newer than existing task, update the task
        %Task{version: existing_version} when version > existing_version ->
          {existing_version, update_task!(state, task)}

        # Task is the same or older than existing task, do nothing
        %Task{version: existing_version} ->
          {existing_version, state}

        # No existing task with this ID, add this one
        nil ->
          {nil, add_task!(state, task)}
      end
    end

    defp add_task!(
           %State{tasks: tasks, app_tasks: app_tasks} = state,
           %Task{id: id, app_id: app_id} = task
         ) do
      %{
        state
        | tasks: Map.put(tasks, id, task),
          app_tasks: Map.update!(app_tasks, app_id, fn tasks -> MapSet.put(tasks, id) end)
      }
    end

    defp update_task!(%State{tasks: tasks} = state, %Task{id: id} = task),
      do: %{state | tasks: Map.replace!(tasks, id, task)}

    @doc """
    Delete a task from `state`.

    Returns the new state. If the task is not in `state`, returns `state`
    unchanged.

    Raises a `KeyError` if the app that the task belongs to is not in `state`.
    """
    def delete_task!(%State{tasks: tasks, app_tasks: app_tasks} = state, %Task{
          id: id,
          app_id: app_id
        }) do
      %{
        state
        | tasks: Map.delete(tasks, id),
          app_tasks: Map.update!(app_tasks, app_id, fn tasks -> MapSet.delete(tasks, id) end)
      }
    end
  end
end
