defmodule FakeMarathon do
  @moduledoc """
  A fake Marathon API that can stream events.
  """
  use GenServer

  defmodule State do
    defstruct listener: nil, apps: [], app_tasks: %{}, event_streams: []
  end

  def response(req, fm, status_code, json) do
    headers = %{"content-type" => "application/json"}
    {:ok, body} = Jason.encode(json)
    {:ok, :cowboy_req.reply(status_code, headers, body, req), fm}
  end

  defmodule AppsHandler do
    @behaviour :cowboy_handler

    def init(req, fm) do
      embed =
        req.qs
        |> URI.query_decoder()
        |> Enum.filter(fn {key, _value} -> key == "embed" end)
        |> Enum.map(fn {_key, value} -> value end)

      FakeMarathon.response(req, fm, 200, %{"apps" => FakeMarathon.get_apps(fm, embed)})
    end
  end

  defmodule AppTasksHandler do
    @behaviour :cowboy_handler

    def init(req, fm) do
      app_id = "/" <> :cowboy_req.binding(:app_id, req)

      case FakeMarathon.get_app_tasks(fm, app_id) do
        nil ->
          FakeMarathon.response(req, fm, 404, %{"message" => "App '#{app_id}' does not exist"})

        app_tasks ->
          FakeMarathon.response(req, fm, 200, %{"tasks" => app_tasks})
      end
    end
  end

  defmodule SSEHandler do
    @behaviour :cowboy_loop

    defmodule StreamOpts do
      defstruct response_delay: 0
    end

    defmodule State do
      @enforce_keys [:fake_marathon]
      defstruct fake_marathon: nil, opts: %StreamOpts{}

      def new(fake_marathon, opts) do
        stream_opts = struct!(StreamOpts, opts)
        %__MODULE__{fake_marathon: fake_marathon, opts: stream_opts}
      end
    end

    @impl :cowboy_loop
    def init(req = %{method: "GET"}, state) do
      case :cowboy_req.parse_header("accept", req) do
        [{{"text", "event-stream", _}, _, _}] -> handle_sse_stream(req, state)
        _ -> {:ok, :cowboy_req.reply(406, req), state}
      end
    end

    # Reject non-GET methods with a 405.
    @impl :cowboy_loop
    def init(req, state) do
      {:ok, :cowboy_req.reply(405, req), state}
    end

    def handle_sse_stream(req, state) do
      :ok = GenServer.call(state.fake_marathon, {:event_stream, self()})
      if state.opts.response_delay > 0, do: Process.sleep(state.opts.response_delay)
      req_resp = :cowboy_req.stream_reply(200, %{"content-type" => "text/event-stream"}, req)
      {:cowboy_loop, req_resp, state}
    end

    @impl :cowboy_loop
    def info({:stream_bytes, bytes}, req, state) do
      :ok = :cowboy_req.stream_body(bytes, :nofin, req)
      {:ok, req, state}
    end

    @impl :cowboy_loop
    def info(:close, req, state), do: {:stop, req, state}

    def send_info(handler, thing), do: send(handler, thing)
  end

  ## Client

  def start_link(args_and_opts) do
    {opts, args} = Keyword.split(args_and_opts, [:name])
    GenServer.start_link(__MODULE__, args, opts)
  end

  def port(fm \\ :fake_marathon), do: GenServer.call(fm, :port)
  def base_url(fm \\ :fake_marathon), do: "http://localhost:#{port(fm)}"
  def events_url(fm \\ :fake_marathon), do: base_url(fm) <> "/v2/events"

  def event(fm \\ :fake_marathon, event, data), do: GenServer.call(fm, {:event, event, data})

  def mk_event(fm \\ :fake_marathon, event_type, fields) do
    e = TestHelpers.marathon_event(event_type, fields)
    event(fm, e.event, e.data)
  end

  def keepalive(fm \\ :fake_marathon), do: GenServer.call(fm, :keepalive)

  def end_stream(fm \\ :fake_marathon), do: GenServer.call(fm, :end_stream)

  def get_apps(fm \\ :fake_marathon, embed), do: GenServer.call(fm, {:get_apps, embed})

  def get_app_tasks(fm \\ :fake_marathon, app_id),
    do: GenServer.call(fm, {:get_app_tasks, app_id})

  def set_apps(fm \\ :fake_marathon, apps), do: GenServer.call(fm, {:set_apps, apps})

  def set_app_tasks(fm \\ :fake_marathon, app_id, tasks),
    do: GenServer.call(fm, {:set_app_tasks, app_id, tasks})

  ## Callbacks

  def init(opts) do
    # Trap exits so terminate/2 gets called reliably.
    Process.flag(:trap_exit, true)
    listener = make_ref()

    handlers = [
      {"/v2/apps", AppsHandler, self()},
      # FIXME: Support app IDs with `/` in them
      {"/v2/apps/:app_id/tasks", AppTasksHandler, self()},
      {"/v2/events", SSEHandler, SSEHandler.State.new(self(), opts)}
    ]

    dispatch = :cowboy_router.compile([{:_, handlers}])
    {:ok, _} = :cowboy.start_clear(listener, [], %{env: %{dispatch: dispatch}})
    {:ok, %State{listener: listener}}
  end

  def terminate(reason, state) do
    :cowboy.stop_listener(state.listener)
    reason
  end

  def handle_call({:event_stream, pid}, _from, state) do
    new_state = %State{state | event_streams: [pid | state.event_streams]}
    {:reply, :ok, new_state}
  end

  def handle_call(:port, _from, state), do: {:reply, :ranch.get_port(state.listener), state}

  def handle_call({:event, event, data}, _from, state),
    do: send_to_handler({:stream_bytes, mkevent(event, data)}, state)

  def handle_call(:keepalive, _from, state),
    do: send_to_handler({:stream_bytes, "\r\n"}, state)

  def handle_call(:end_stream, _from, state),
    do: send_to_handler(:close, state)

  def handle_call({:get_apps, []}, _from, state), do: {:reply, state.apps, state}

  def handle_call({:get_apps, ["apps.tasks"]}, _from, state) do
    response =
      Enum.map(state.apps, fn app ->
        tasks = Map.get(state.app_tasks, app["id"], [])
        Map.put(app, "tasks", tasks)
      end)

    {:reply, response, state}
  end

  def handle_call({:get_app_tasks, app_id}, _from, state),
    do: {:reply, Map.get(state.app_tasks, app_id), state}

  def handle_call({:set_apps, apps}, _from, state), do: {:reply, :ok, %{state | apps: apps}}

  def handle_call({:set_app_tasks, app_id, tasks}, _from, %{app_tasks: app_tasks} = state) do
    {:reply, :ok, %{state | app_tasks: Map.put(app_tasks, app_id, tasks)}}
  end

  defp mkevent(event, data), do: "event: #{event}\r\ndata: #{data}\r\n\r\n"

  defp send_to_handler(thing, state) do
    Enum.each(state.event_streams, &SSEHandler.send_info(&1, thing))
    {:reply, :ok, state}
  end
end
