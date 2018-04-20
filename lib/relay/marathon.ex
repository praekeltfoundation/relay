defmodule Relay.Marathon do
  @moduledoc """
  GenServer to receive Marathon events and update the Store on relevant
  updates.
  """

  alias Relay.Marathon.{App, Store, Task}

  alias MarathonClient.SSEParser.Event

  use GenServer

  use LogWrapper, as: Log

  @terminal_states [
    "TASK_FINISHED",
    "TASK_FAILED",
    "TASK_KILLED",
    "TASK_LOST"
  ]

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {store, opts} = Keyword.pop(opts, :store, Store)
    GenServer.start_link(__MODULE__, store, opts)
  end

  @impl GenServer
  @spec init(GenServer.server()) :: {:ok, GenServer.server()}
  def init(store) do
    send(self(), :sync)

    {:ok, _pid} = stream_events()

    {:ok, store}
  end

  @spec stream_events() :: GenServer.on_start()
  defp stream_events do
    MarathonClient.stream_events(
      marathon_url(),
      [self()],
      Application.fetch_env!(:relay, :marathon) |> Keyword.fetch!(:events_timeout)
    )
  end

  # TODO: Support multiple URLs
  @spec marathon_url() :: String.t()
  defp marathon_url,
    do: Application.fetch_env!(:relay, :marathon) |> Keyword.fetch!(:urls) |> hd()

  @spec marathon_lb_group() :: String.t()
  defp marathon_lb_group,
    do: Application.fetch_env!(:relay, :marathon_lb) |> Keyword.fetch!(:group)

  @impl GenServer
  def handle_info(:sync, store) do
    url = marathon_url()
    group = marathon_lb_group()

    # Get the apps, convert to App structs, filter irrelevant ones
    {:ok, %{"apps" => apps_json}} = MarathonClient.get_apps(url, embed: ["apps.tasks"])

    # Get the tasks for each app, convert to Task structs, store them
    apps_and_tasks =
      apps_json
      |> Stream.map(fn app_json -> {App.from_definition(app_json, group), app_json["tasks"]} end)
      |> Stream.reject(fn {app, _task_json} -> Enum.empty?(app.port_indices) end)
      |> Enum.map(fn {app, tasks_json} ->
        tasks =
          tasks_json
          |> Stream.reject(&(&1["taskStatus"] in @terminal_states))
          |> Enum.map(&Task.from_definition(app, &1))

        {app, tasks}
      end)

    Store.sync(store, apps_and_tasks)

    {:noreply, store}
  end

  @impl GenServer
  def handle_info({:sse, %Event{event: type, data: data}}, store) do
    handle_event(type, data, store)
    {:noreply, store}
  end

  @spec handle_event(String.t(), String.t(), GenServer.server()) :: :ok
  defp handle_event("api_post_event", data, store) do
    {:ok, event} = Poison.decode(data)

    case App.from_event(event, marathon_lb_group()) do
      %App{port_indices: port_indices} = app when length(port_indices) > 0 ->
        log_api_post_event(event, "updating app")
        Store.update_app(store, app)

      %App{id: app_id} ->
        # If the app is not relevant, check if we have it stored already. If we
        # do, we can now delete it from the store.
        case Store.get_app(store, app_id) do
          {:ok, %App{}} ->
            log_api_post_event(event, "deleting app (no longer relevant)")
            Store.delete_app(store, app_id)

          {:ok, nil} ->
            log_api_post_event(event, "ignoring (not relevant)")
        end
    end
  end

  # app_terminated_event is *almost* undocumented but seems to be fired when an
  # app is destroyed. It has been in Marathon for a while:
  # https://github.com/mesosphere/marathon/commit/4d86315a77d994aaf7a52a67ba204cf2e955914a
  defp handle_event("app_terminated_event", data, store) do
    {:ok, %{"appId" => app_id}} = Poison.decode(data)
    Log.debug("app_terminated_event for app '#{app_id}': deleting app")
    Store.delete_app(store, app_id)
  end

  defp handle_event("status_update_event", data, store) do
    {:ok, %{"appId" => app_id, "taskId" => task_id} = event} = Poison.decode(data)

    case event do
      %{"taskStatus" => task_status} when task_status in @terminal_states ->
        log_status_update_event(event, "deleting task (terminal state)")
        Store.delete_task(store, task_id, app_id)

      _ ->
        # Update the task if we have the app for it already stored
        case Store.get_app(store, app_id) do
          {:ok, %App{} = app} ->
            log_status_update_event(event, "updating task")
            Store.update_task(store, Task.from_event(app, event))

          {:ok, nil} ->
            log_status_update_event(event, "ignoring (app not relevant)")
        end
    end
  end

  defp handle_event(type, _data, _store), do: Log.debug("Ignoring event of type '#{type}'")

  @spec log_api_post_event(map, String.t()) :: :ok
  defp log_api_post_event(%{"appDefinition" => %{"id" => id}}, action),
    do: Log.debug("api_post_event for app '#{id}': #{action}")

  @spec log_status_update_event(map, String.t()) :: :ok
  defp log_status_update_event(%{"taskStatus" => status, "taskId" => id}, action),
    do: Log.debug("status_update_event (#{status}) for task '#{id}': #{action}")
end
