defmodule EventCatcher do
  @moduledoc """
  A listener that stashes received events.
  """
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, [], opts)
  def events(server), do: GenServer.call(server, :events)

  def init(args), do: {:ok, args}

  def handle_call(:events, _from, events), do: {:reply, events, events}
  def handle_info({:sse, event}, events), do: {:noreply, [event | events]}
end

defmodule TestHelpers do
  alias Relay.MarathonClient.SSEParser.Event

  @doc """
  Build a Marathon event from the given type and fields.

  The :eventType field is always added/overridden, the :timestamp field is
  added if one is not provided.
  """
  def marathon_event(event_type, fields) do
    {:ok, data} = Map.new(fields)
    |> Map.put_new(:timestamp, DateTime.utc_now |> DateTime.to_iso8601)
    |> Map.put(:eventType, event_type)
    |> JSX.encode
    %Event{event: event_type, data: data}
  end
end

defmodule FakeMarathon do
  @moduledoc """
  A fake Marathon API that can stream events.
  """
  use GenServer

  alias SSETestServer.SSEServer

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

  ## Callbacks

  def init(opts) do
    {:ok, sse_pid} = SSEServer.start_link(opts, name: nil)
    SSEServer.configure_endpoint(sse_pid, "/v2/events", opts)
    {:ok, sse_pid}
  end

  def handle_call(:port, _from, sse_pid),
    do: {:reply, SSEServer.port(sse_pid), sse_pid}

  def handle_call({:event, event, data}, _from, sse_pid),
    do: {:reply, SSEServer.event(sse_pid, "/v2/events", event, data), sse_pid}

  def handle_call(:keepalive, _from, sse_pid),
    do: {:reply, SSEServer.keepalive(sse_pid, "/v2/events"), sse_pid}

  def handle_call(:end_stream, _from, sse_pid),
    do: {:reply, SSEServer.end_stream(sse_pid, "/v2/events"), sse_pid}
end
