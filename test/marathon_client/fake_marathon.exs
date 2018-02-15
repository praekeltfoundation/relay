defmodule FakeMarathon do
  @moduledoc """
  A fake Marathon API that can stream events.
  """
  use GenServer

  alias SSETestServer.SSEServer

  defmodule State do
    defstruct sse: nil, listener: nil, apps: []
  end

  defmodule AppsHandler do
    @behaviour :cowboy_handler

    def init(req, fm) do
      headers = %{"content-type" => "application/json"}
      {:ok, apps} = JSX.encode(%{"apps" => FakeMarathon.get_apps(fm)})
      {:ok, :cowboy_req.reply(200, headers, apps, req), fm}
    end
  end

  ## Client

  def start_link(args_and_opts) do
    {opts, args} = Keyword.split(args_and_opts, [:name])
    GenServer.start_link(__MODULE__, args, opts)
  end

  def port(fm \\ :fake_marathon), do: GenServer.call(fm, :port)
  def base_url(fm \\ :fake_marathon), do: "http://localhost:#{port(fm)}"
  def events_url(fm \\ :fake_marathon), do: base_url(fm) <> "/v2/events"

  def event(fm \\ :fake_marathon, event, data),
    do: GenServer.call(fm, {:event, event, data})

  def mk_event(fm \\ :fake_marathon, event_type, fields) do
    e = TestHelpers.marathon_event(event_type, fields)
    event(fm, e.event, e.data)
  end

  def keepalive(fm \\ :fake_marathon), do: GenServer.call(fm, :keepalive)

  def end_stream(fm \\ :fake_marathon), do: GenServer.call(fm, :end_stream)

  def get_apps(fm \\ :fake_marathon), do: GenServer.call(fm, :get_apps)

  def set_apps(fm \\ :fake_marathon, apps),
    do: GenServer.call(fm, {:set_apps, apps})

  ## Callbacks

  def init(opts) do
    # Trap exits so terminate/2 gets called reliably.
    Process.flag(:trap_exit, true)
    {:ok, sse} = SSEServer.start_link(opts, name: nil)
    listener = make_ref()
    handlers = [
      {"/v2/apps", AppsHandler, self()},
      SSEServer.configure_endpoint_handler(sse, "/v2/events", opts),
    ]
    dispatch = :cowboy_router.compile([{:_, handlers}])
    {:ok, _} = :cowboy.start_clear(listener, [], %{env: %{dispatch: dispatch}})
    {:ok, %State{sse: sse, listener: listener}}
  end

  def terminate(reason, state) do
    :cowboy.stop_listener(state.listener)
    reason
  end

  def handle_call(:port, _from, state),
    do: {:reply, :ranch.get_port(state.listener), state}

  def handle_call({:event, event, data}, _from, state),
    do: {:reply, SSEServer.event(state.sse, "/v2/events", event, data), state}

  def handle_call(:keepalive, _from, state),
    do: {:reply, SSEServer.keepalive(state.sse, "/v2/events"), state}

  def handle_call(:end_stream, _from, state),
    do: {:reply, SSEServer.end_stream(state.sse, "/v2/events"), state}

  def handle_call(:get_apps, _from, state), do: {:reply, state.apps, state}

  def handle_call({:set_apps, apps}, _from, state),
    do: {:reply, :ok, %{state | apps: apps}}
end
