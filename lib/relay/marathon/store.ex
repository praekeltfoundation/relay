defmodule Relay.Marathon.Store do
  alias Relay.Marathon.{App, Task}

  use GenServer
  require Logger

  defmodule State do
    defstruct apps: %{}, tasks: %{}, app_tasks: %{}

    @type t :: %__MODULE__{
            apps: %{optional(String.t()) => App.t()},
            tasks: %{optional(String.t()) => Task.t()},
            app_tasks: %{optional(String.t()) => String.t()}
          }

    @spec get_and_update_app(t, App.t()) :: {App.t() | nil, t}
    def get_and_update_app(%__MODULE__{apps: apps} = state, %App{id: id, version: version} = app) do
      case Map.get(apps, id) do
        # App is newer than existing app, update the app
        %App{version: existing_version} = existing_app when version > existing_version ->
          {existing_app, replace_app!(state, app)}

        # App is the same or older than existing app, do nothing
        %App{} ->
          {app, state}

        # No existing app with this ID, add this one
        nil ->
          {nil, put_app(state, app)}
      end
    end

    @spec put_app(t, App.t()) :: t
    defp put_app(%__MODULE__{apps: apps, app_tasks: app_tasks} = state, %App{id: id} = app),
      do: %{state | apps: Map.put(apps, id, app), app_tasks: Map.put(app_tasks, id, MapSet.new())}

    @spec replace_app!(t, App.t()) :: t
    defp replace_app!(%__MODULE__{apps: apps} = state, %App{id: id} = app),
      do: %{state | apps: Map.replace!(apps, id, app)}

    @spec pop_app(t, String.t()) :: {App.t() | nil, t}
    def pop_app(%__MODULE__{apps: apps, tasks: tasks, app_tasks: app_tasks} = state, id) do
      case Map.pop(apps, id) do
        {%App{} = app, new_apps} ->
          {tasks_for_app, new_app_tasks} = Map.pop(app_tasks, id)
          new_tasks = Map.drop(tasks, tasks_for_app)

          {app, %{state | apps: new_apps, tasks: new_tasks, app_tasks: new_app_tasks}}

        {nil, _} ->
          {nil, state}
      end
    end

    @spec get_and_update_task!(t, Task.t()) :: {Task.t() | nil, t}
    def get_and_update_task!(
          %__MODULE__{tasks: tasks} = state,
          %Task{id: id, version: version} = task
        ) do
      case Map.get(tasks, id) do
        # Task is newer than existing task, update the task
        %Task{version: existing_version} = existing_task when version > existing_version ->
          {existing_task, replace_task!(state, task)}

        # Task is the same or older than existing task, do nothing
        %Task{} ->
          {task, state}

        # No existing task with this ID, add this one
        nil ->
          {nil, put_task!(state, task)}
      end
    end

    @spec put_task!(t, Task.t()) :: t
    defp put_task!(
           %__MODULE__{tasks: tasks, app_tasks: app_tasks} = state,
           %Task{id: id, app_id: app_id} = task
         ) do
      %{
        state
        | tasks: Map.put(tasks, id, task),
          app_tasks: Map.update!(app_tasks, app_id, fn tasks -> MapSet.put(tasks, id) end)
      }
    end

    @spec replace_task!(t, Task.t()) :: t
    defp replace_task!(%__MODULE__{tasks: tasks} = state, %Task{id: id} = task),
      do: %{state | tasks: Map.replace!(tasks, id, task)}

    @spec pop_task(t, String.t()) :: {Task.t() | nil, t}
    def pop_task(%__MODULE__{tasks: tasks, app_tasks: app_tasks} = state, id) do
      case Map.pop(tasks, id) do
        {%Task{app_id: app_id} = task, new_tasks} ->
          new_app_tasks = Map.update!(app_tasks, app_id, &MapSet.delete(&1, id))

          {task, %{state | tasks: new_tasks, app_tasks: new_app_tasks}}

        {nil, _} ->
          {nil, state}
      end
    end
  end

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Update an app in the Store. The app is only added if its version is newer than
  any existing app.
  """
  @spec update_app(GenServer.server(), App.t()) :: :ok
  def update_app(store, %App{} = app), do: GenServer.call(store, {:update_app, app})

  @doc """
  Delete an app from the Store. All tasks for the app will also be removed.
  """
  @spec delete_app(GenServer.server(), String.t()) :: :ok
  def delete_app(store, app_id), do: GenServer.call(store, {:delete_app, app_id})

  @doc """
  Update a task in the Store. The task is only added if its version is newer
  than any existing task.
  """
  @spec update_task(GenServer.server(), Task.t()) :: :ok
  def update_task(store, %Task{} = task), do: GenServer.call(store, {:update_task, task})

  @doc """
  Delete a task from the Store.
  """
  @spec delete_task(GenServer.server(), String.t()) :: :ok
  def delete_task(store, task_id), do: GenServer.call(store, {:delete_task, task_id})

  def init(_arg) do
    {:ok, %State{}}
  end

  def handle_call({:update_app, %App{id: id, version: version} = app}, _from, state) do
    {old_app, new_state} = State.get_and_update_app(state, app)

    _ =
      case old_app do
        %App{version: existing_version} when version > existing_version ->
          _ = Logger.debug("App '#{id}' updated: #{existing_version} -> #{version}")
          notify_updated_app()

        %App{version: existing_version} ->
          Logger.debug("App '#{id}' unchanged: #{version} <= #{existing_version}")

        nil ->
          _ = Logger.info("App '#{id}' with version #{version} added")
          notify_updated_app()
      end

    {:reply, :ok, new_state}
  end

  def handle_call({:delete_app, id}, _from, state) do
    {app, new_state} = State.pop_app(state, id)

    _ =
      case app do
        %App{version: version} ->
          _ = Logger.info("App '#{id}' with version #{version} deleted")
          notify_updated_app()

        nil ->
          Logger.debug("App '#{id}' not present/already deleted")
      end

    {:reply, :ok, new_state}
  end

  def handle_call(
        {:update_task, %Task{id: id, app_id: app_id, version: version} = task},
        _from,
        state
      ) do
    new_state =
      try do
        {old_task, new_state} = State.get_and_update_task!(state, task)

        _ =
          case old_task do
            %Task{version: existing_version} when version > existing_version ->
              _ = Logger.debug("Task '#{id}' updated: #{existing_version} -> #{version}")
              notify_updated_task()

            %Task{version: existing_version} ->
              Logger.debug("Task '#{id}' unchanged: #{version} <= #{existing_version}")

            nil ->
              Logger.info("Task '#{id}' with version #{version} added")
              notify_updated_task()
          end

        new_state
      rescue
        KeyError ->
          _ = Logger.warn("Unable to find app '#{app_id}' for task '#{id}'. Task update ignored.")
          state
      end

    {:reply, :ok, new_state}
  end

  def handle_call({:delete_task, id}, _from, state) do
    {task, new_state} = State.pop_task(state, id)

    _ =
      case task do
        %Task{version: version} ->
          _ = Logger.info("Task '#{id}' with version #{version} deleted")
          notify_updated_task()

        nil ->
          Logger.debug("Task '#{id}' not present/already deleted")
      end

    {:reply, :ok, new_state}
  end

  # For testing only
  def handle_call(:_get_state, _from, state), do: {:reply, {:ok, state}, state}

  defp notify_updated_app do
    Logger.debug("An app was updated, we should update CDS and RDS...")
  end

  defp notify_updated_task do
    Logger.debug("A task was updated, we should updated EDS...")
  end
end
