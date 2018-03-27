defmodule Relay.Marathon.State do
  @moduledoc """
  Box to keep Marathon state all neatly organised in.
  """

  alias Relay.Marathon.{App, Task}

  defstruct apps: %{}, tasks: %{}, app_tasks: %{}

  @type t :: %__MODULE__{
          apps: %{optional(String.t()) => App.t()},
          tasks: %{optional(String.t()) => Task.t()},
          app_tasks: %{optional(String.t()) => String.t()}
        }

  @doc """
  Add an app to `state`. The app is only added if its version is newer than
  the existing app.

  Returns a tuple where the first element is the version of the app already in
  the state (or `nil` if there was no app with the ID) and the second element
  is the new state.
  """
  @spec put_app(t, App.t()) :: {String.t() | nil, t}
  def put_app(%__MODULE__{apps: apps} = state, %App{id: id, version: version} = app) do
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

  @spec add_app(t, App.t()) :: t
  defp add_app(%__MODULE__{apps: apps, app_tasks: app_tasks} = state, %App{id: id} = app),
    do: %{state | apps: Map.put(apps, id, app), app_tasks: Map.put(app_tasks, id, MapSet.new())}

  @spec update_app!(t, App.t()) :: t
  defp update_app!(%__MODULE__{apps: apps} = state, %App{id: id} = app),
    do: %{state | apps: Map.replace!(apps, id, app)}

  @doc """
  Delete an app from the state. All tasks for the app will also be removed.

  Returns the new state. If the app is not in `state`, returns `state`
  unchanged.
  """
  @spec delete_app(t, App.t()) :: t
  def delete_app(%__MODULE__{apps: apps, tasks: tasks, app_tasks: app_tasks} = state, %App{id: id}) do
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
  @spec put_task!(t, Task.t()) :: {String.t() | nil, t}
  def put_task!(%__MODULE__{tasks: tasks} = state, %Task{id: id, version: version} = task) do
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

  @spec add_task!(t, Task.t()) :: t
  defp add_task!(
         %__MODULE__{tasks: tasks, app_tasks: app_tasks} = state,
         %Task{id: id, app_id: app_id} = task
       ) do
    %{
      state
      | tasks: Map.put(tasks, id, task),
        app_tasks: Map.update!(app_tasks, app_id, fn tasks -> MapSet.put(tasks, id) end)
    }
  end

  @spec update_task!(t, Task.t()) :: t
  defp update_task!(%__MODULE__{tasks: tasks} = state, %Task{id: id} = task),
    do: %{state | tasks: Map.replace!(tasks, id, task)}

  @doc """
  Delete a task from `state`.

  Returns the new state. If the task is not in `state`, returns `state`
  unchanged.

  Raises a `KeyError` if the app that the task belongs to is not in `state`.
  """
  @spec delete_task!(t, Task.t()) :: t
  def delete_task!(%__MODULE__{tasks: tasks, app_tasks: app_tasks} = state, %Task{
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
