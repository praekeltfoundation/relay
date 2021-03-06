defmodule Relay.Marathon.Store do
  @moduledoc """
  A store for Marathon apps and tasks. Keeps a mapping of apps to their tasks
  and triggers updates when a new version of an app or task is stored.
  """

  alias Relay.Marathon.{Adapter, App, Task}
  alias Relay.Resources

  use LogWrapper, as: Log

  use GenServer

  defmodule State do
    @moduledoc false

    defstruct [:version, apps: %{}, app_tasks: %{}]

    @type t :: %__MODULE__{
            version: String.t(),
            apps: %{optional(String.t()) => App.t()},
            app_tasks: %{optional(String.t()) => %{optional(String.t()) => Task.t()}}
          }

    def new, do: %State{version: new_version()}

    @spec set_apps_and_tasks(t, [{App.t(), [Task.t()]}]) :: t
    def set_apps_and_tasks(state, apps_and_tasks) do
      apps =
        apps_and_tasks
        |> Enum.into(%{}, fn {%App{id: app_id} = app, _} -> {app_id, app} end)

      app_tasks =
        apps_and_tasks
        |> Enum.into(%{}, fn {%App{id: app_id}, tasks_list} ->
          tasks =
            tasks_list
            |> Enum.into(%{}, fn %Task{id: task_id} = task -> {task_id, task} end)

          {app_id, tasks}
        end)

      new_state(state, apps: apps, app_tasks: app_tasks)
    end

    @spec get_apps(t) :: [App.t()]
    def get_apps(%__MODULE__{apps: apps}), do: values_sorted_by_key(apps)

    @spec get_apps_and_tasks(t) :: [{App.t(), [Task.t()]}]
    def get_apps_and_tasks(%__MODULE__{} = state) do
      state
      |> get_apps()
      |> Enum.map(fn app -> {app, get_tasks(state, app)} end)
    end

    @spec get_tasks(t, App.t()) :: [Task.t()]
    defp get_tasks(%__MODULE__{app_tasks: app_tasks}, %App{id: app_id}),
      do: values_sorted_by_key(app_tasks[app_id])

    @spec values_sorted_by_key(%{optional(Map.key()) => Map.value()}) :: [Map.value()]
    defp values_sorted_by_key(map),
      do: map |> Map.to_list() |> Enum.sort() |> Enum.map(&elem(&1, 1))

    @spec get_app(t, String.t()) :: App.t() | nil
    def get_app(%__MODULE__{apps: apps}, app_id), do: Map.get(apps, app_id)

    @spec get_and_update_app(t, App.t()) :: {App.t() | nil, t}
    def get_and_update_app(state, %App{id: id, version: version} = app) do
      case State.get_app(state, id) do
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
      do: new_state(state, apps: Map.put(apps, id, app), app_tasks: Map.put(app_tasks, id, %{}))

    @spec replace_app!(t, App.t()) :: t
    defp replace_app!(%__MODULE__{apps: apps} = state, %App{id: id} = app),
      do: new_state(state, apps: Map.replace!(apps, id, app))

    @spec pop_app(t, String.t()) :: {App.t() | nil, t}
    def pop_app(%__MODULE__{apps: apps, app_tasks: app_tasks} = state, id) do
      case Map.pop(apps, id) do
        {%App{} = app, new_apps} ->
          {app, new_state(state, apps: new_apps, app_tasks: Map.delete(app_tasks, id))}

        {nil, _} ->
          {nil, state}
      end
    end

    @spec get_and_update_task!(t, Task.t()) :: {Task.t() | nil, t}
    def get_and_update_task!(
          %__MODULE__{app_tasks: app_tasks} = state,
          %Task{id: id, app_id: app_id, version: version} = task
        ) do
      tasks = Map.fetch!(app_tasks, app_id)

      case Map.get(tasks, id) do
        # Task is newer than existing task, update the task
        %Task{version: existing_version} = existing_task when version > existing_version ->
          {existing_task, put_task!(state, tasks, task)}

        # Task is the same or older than existing task, do nothing
        %Task{} ->
          {task, state}

        # No existing task with this ID, add this one
        nil ->
          {nil, put_task!(state, tasks, task)}
      end
    end

    @spec put_task!(t, %{String.t() => %{optional(String.t()) => Task.t()}}, Task.t()) :: t
    defp put_task!(
           %__MODULE__{app_tasks: app_tasks} = state,
           tasks,
           %Task{id: id, app_id: app_id} = task
         ) do
      new_tasks = Map.put(tasks, id, task)
      new_state(state, app_tasks: Map.replace!(app_tasks, app_id, new_tasks))
    end

    @spec pop_task!(t, String.t(), String.t()) :: {Task.t() | nil, t}
    def pop_task!(%__MODULE__{app_tasks: app_tasks} = state, id, app_id) do
      tasks = Map.fetch!(app_tasks, app_id)

      case Map.pop(tasks, id) do
        {%Task{} = task, new_tasks} ->
          {task, new_state(state, app_tasks: Map.replace!(app_tasks, app_id, new_tasks))}

        {nil, _} ->
          {nil, state}
      end
    end

    @spec new_state(t, keyword) :: t
    defp new_state(state, updates), do: struct(state, [version: new_version()] ++ updates)

    @spec new_version() :: String.t()
    defp new_version do
      time = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

      # Take last 6 digits of unique_integer and pad with leading 0's.
      number =
        System.unique_integer([:monotonic, :positive])
        |> Integer.mod(1_000_000)
        |> Integer.to_string()
        |> String.pad_leading(6, "0")

      "#{time}-#{number}"
    end
  end

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {resources, opts} = Keyword.pop(opts, :resources, Resources)
    GenServer.start_link(__MODULE__, resources, opts)
  end

  @doc """
  Sync all apps and tasks. Simply replaces the existing apps and tasks in the
  store with those provided.
  """
  @spec sync(GenServer.server(), [{App.t(), [Task.t()]}]) :: :ok
  def sync(store, apps_and_tasks), do: GenServer.call(store, {:sync, apps_and_tasks})

  @doc """
  Get an app from the store using its ID.

  We need to check for the presence of an App in the Store to determine whether
  a Task is relevant to us. Also, Task structs require the corresponding App
  struct in order to be created.
  """
  @spec get_app(GenServer.server(), String.t()) :: {:ok, App.t() | nil}
  def get_app(store, app_id), do: GenServer.call(store, {:get_app, app_id})

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

  An error will be raised if the task's app is not already stored.
  """
  @spec update_task(GenServer.server(), Task.t()) :: :ok
  def update_task(store, %Task{} = task), do: GenServer.call(store, {:update_task, task})

  @doc """
  Delete a task from the Store.

  If the app ID is not in the store, this task deletion will be ignored.
  """
  @spec delete_task(GenServer.server(), String.t(), String.t()) :: :ok
  def delete_task(store, task_id, app_id),
    do: GenServer.call(store, {:delete_task, task_id, app_id})

  @spec init(GenServer.server()) :: {:ok, {GenServer.server(), State.t()}}
  def init(resources) do
    {:ok, {resources, State.new()}}
  end

  def handle_call({:sync, apps_and_tasks}, _from, {resources, state}) do
    Log.info("Syncing all apps and tasks...")
    new_state = State.set_apps_and_tasks(state, apps_and_tasks)
    notify_sync(resources, new_state)

    {:reply, :ok, {resources, new_state}}
  end

  def handle_call({:get_app, app_id}, _from, {resources, state}),
    do: {:reply, {:ok, State.get_app(state, app_id)}, {resources, state}}

  def handle_call({:update_app, %App{id: id, version: version} = app}, _from, {resources, state}) do
    {old_app, new_state} = State.get_and_update_app(state, app)

    case old_app do
      %App{version: existing_version} when version > existing_version ->
        Log.debug("App '#{id}' updated: #{existing_version} -> #{version}")
        notify_updated_app(resources, new_state)

      %App{version: existing_version} ->
        Log.debug("App '#{id}' unchanged: #{version} <= #{existing_version}")

      nil ->
        Log.info("App '#{id}' with version #{version} added")
        notify_updated_app(resources, new_state)
    end

    {:reply, :ok, {resources, new_state}}
  end

  def handle_call({:delete_app, id}, _from, {resources, state}) do
    {app, new_state} = State.pop_app(state, id)

    case app do
      %App{version: version} ->
        Log.info("App '#{id}' with version #{version} deleted")
        notify_updated_app(resources, new_state)

      nil ->
        Log.debug("App '#{id}' not present/already deleted")
    end

    {:reply, :ok, {resources, new_state}}
  end

  def handle_call(
        {:update_task, %Task{id: id, version: version} = task},
        _from,
        {resources, state}
      ) do
    # If the app for the task doesn't exist it's an error
    {old_task, new_state} = State.get_and_update_task!(state, task)

    case old_task do
      %Task{version: existing_version} when version > existing_version ->
        Log.debug("Task '#{id}' updated: #{existing_version} -> #{version}")
        notify_updated_task(resources, new_state)

      %Task{version: existing_version} ->
        Log.debug("Task '#{id}' unchanged: #{version} <= #{existing_version}")

      nil ->
        Log.info("Task '#{id}' with version #{version} added")
        notify_updated_task(resources, new_state)
    end

    {:reply, :ok, {resources, new_state}}
  end

  def handle_call({:delete_task, id, app_id}, _from, {resources, state}) do
    new_state =
      try do
        {task, new_state} = State.pop_task!(state, id, app_id)

        case task do
          %Task{version: version} ->
            Log.info("Task '#{id}' with version #{version} deleted")
            notify_updated_task(resources, new_state)

          nil ->
            Log.debug("Task '#{id}' not present/already deleted")
        end

        new_state
      rescue
        KeyError ->
          Log.debug("Unable to find app '#{app_id}' for task '#{id}'. Task delete ignored.")
          state
      end

    {:reply, :ok, {resources, new_state}}
  end

  # For testing only
  def handle_call(:_get_state, _from, {resources, state}),
    do: {:reply, {:ok, state}, {resources, state}}

  @spec notify_sync(GenServer.server(), State.t()) :: :ok
  defp notify_sync(resources, state) do
    Log.debug("Apps and tasks were synced, updating app endpoints")
    # TODO: Split CDS/RDS from EDS updates in Resources so that this does
    # what both notify_updated_task/1 notify_updated_app/1 would do
    update_app_endpoints(resources, state)
  end

  @spec notify_updated_app(GenServer.server(), State.t()) :: :ok
  defp notify_updated_app(resources, state) do
    Log.debug("An app was updated, updating app endpoints")
    # TODO: Split CDS/RDS from EDS updates in Resources so that this does
    # something different from notify_updated_task/1
    update_app_endpoints(resources, state)
  end

  @spec notify_updated_task(GenServer.server(), State.t()) :: :ok
  defp notify_updated_task(resources, state) do
    Log.debug("A task was updated, updating app endpoints...")
    # TODO: Split CDS/RDS from EDS updates in Resources so that this does
    # something different from notify_updated_app/1
    update_app_endpoints(resources, state)
  end

  @spec update_app_endpoints(GenServer.server(), State.t()) :: :ok
  defp update_app_endpoints(resources, %State{version: version, apps: apps}) when apps == %{},
    do: Resources.update_app_endpoints(resources, version, [])

  defp update_app_endpoints(resources, state) do
    app_endpoints =
      state
      |> State.get_apps_and_tasks()
      |> Enum.flat_map(fn {app, tasks} -> Adapter.app_endpoints_for_app(app, tasks) end)

    Resources.update_app_endpoints(resources, state.version, app_endpoints)
  end
end
