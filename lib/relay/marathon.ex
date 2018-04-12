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
    {:ok, _pid} = stream_events()

    {:ok, store}
  end

  @spec stream_events() :: GenServer.on_start()
  defp stream_events do
    marathon_config = Application.fetch_env!(:relay, :marathon)

    MarathonClient.stream_events(
      # TODO: Support multiple URLs
      marathon_config |> Keyword.fetch!(:urls) |> Enum.at(0),
      [self()],
      Keyword.fetch!(marathon_config, :events_timeout)
    )
  end

  @spec marathon_lb_group() :: String.t()
  defp marathon_lb_group,
    do: Application.fetch_env!(:relay, :marathon_lb) |> Keyword.fetch!(:group)

  @impl GenServer
  def handle_info({:sse, %Event{event: "api_post_event", data: event_data}}, store) do
    {:ok, event} = Poison.decode(event_data)
    handle_api_post_event(event, store)

    {:noreply, store}
  end

  # app_terminated_event is *almost* undocumented but seems to be fired when an
  # app is destroyed. It has been in Marathon for a while:
  # https://github.com/mesosphere/marathon/commit/4d86315a77d994aaf7a52a67ba204cf2e955914a
  def handle_info({:sse, %Event{event: "app_terminated_event", data: event_data}}, store) do
    {:ok, event} = Poison.decode(event_data)
    handle_app_terminated_event(event, store)

    {:noreply, store}
  end

  def handle_info({:sse, %Event{event: "status_update_event", data: event_data}}, store) do
    {:ok, event} = Poison.decode(event_data)
    handle_status_update_event(event, store)

    {:noreply, store}
  end

  def handle_info({:sse, %Event{event: event_type}}, state) do
    Log.debug("Ignoring event of type '#{event_type}'")
    {:noreply, state}
  end

  @spec handle_api_post_event(map, GenServer.server()) :: :ok
  defp handle_api_post_event(event, store) do
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

  @spec log_api_post_event(map, String.t()) :: :ok
  defp log_api_post_event(%{"appDefinition" => %{"id" => id}}, action),
    do: Log.debug("api_post_event for app '#{id}': #{action}")

  @spec handle_app_terminated_event(map, GenServer.server()) :: :ok
  defp handle_app_terminated_event(%{"appId" => app_id}, store) do
    Log.debug("app_terminated_event for app '#{app_id}': deleting app")
    Store.delete_app(store, app_id)
  end

  @spec handle_status_update_event(map, GenServer.server()) :: :ok
  defp handle_status_update_event(%{"taskStatus" => task_status} = event, store)
       when task_status in @terminal_states do
    %{"appId" => app_id, "taskId" => task_id} = event
    log_status_update_event(event, "deleting task (terminal state)")
    Store.delete_task(store, task_id, app_id)
  end

  defp handle_status_update_event(%{"appId" => app_id} = event, store) do
    # Update the task if we have the app for it already stored
    case Store.get_app(store, app_id) do
      {:ok, %App{} = app} ->
        log_status_update_event(event, "updating task")
        Store.update_task(store, Task.from_event(app, event))

      {:ok, nil} ->
        log_status_update_event(event, "ignoring (app not relevant)")
    end
  end

  @spec log_status_update_event(map, String.t()) :: :ok
  defp log_status_update_event(%{"taskStatus" => status, "taskId" => id}, action),
    do: Log.debug("status_update_event (#{status}) for task '#{id}': #{action}")
end
