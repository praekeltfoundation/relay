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

  def handle_info({:sse, %Event{event: "api_post_event", data: event_data}}, store) do
    {:ok, event} = Poison.decode(event_data)
    handle_api_post_event(event, store)

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
        Log.debug("api_post_event for app '#{app.id}': updating app...")
        Store.update_app(store, app)

      app ->
        Log.debug("api_post_event for app '#{app.id}': ignored")
    end
  end

  @spec handle_status_update_event(map, GenServer.server()) :: :ok
  defp handle_status_update_event(%{"taskStatus" => task_status} = event, store)
       when task_status in @terminal_states do
    %{"appId" => app_id, "taskId" => task_id} = event
    Log.debug("status_update_event (#{task_status}) for task '#{task_id}': deleting...")
    Store.delete_task(store, task_id, app_id)
  end

  defp handle_status_update_event(event, store) do
    %{"taskStatus" => task_status, "appId" => app_id, "taskId" => task_id} = event

    # Update the task if we have the app for it already stored
    case Store.get_app(store, app_id) do
      {:ok, %App{} = app} ->
        Log.debug("status_update_event (#{task_status}) for task '#{task_id}': updating...")
        Store.update_task(store, Task.from_event(app, event))

      {:ok, nil} ->
        Log.debug("status_update_event (#{task_status}) for task '#{task_id}': ignored (no app)")
    end
  end
end
