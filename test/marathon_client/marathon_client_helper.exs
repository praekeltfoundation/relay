Code.require_file(Path.join([__DIR__, "fake_marathon.exs"]))

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

defmodule MarathonTestHelpers do
  alias MarathonClient.SSEParser.Event

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
