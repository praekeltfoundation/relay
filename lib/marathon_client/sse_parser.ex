defmodule MarathonClient.SSEParser do
  @moduledoc """
  A GenServer to turn a stream of bytes (usually from an HTTP response) into a
  stream of server-sent events.

  See https://html.spec.whatwg.org/multipage/server-sent-events.html
  (particularly sections 9.2.4 and 9.2.5) for the protocol specification.
  """

  use GenServer

  defmodule Event do
    @moduledoc "SSE event struct."
    defstruct data: "", event: "", id: ""
  end

  defimpl String.Chars, for: Event do
    def to_string(event) do
      "#Event<#{event.event} #{inspect(event.data)} id=#{inspect(event.id)}>"
    end
  end

  defmodule State do
    @moduledoc false
    defstruct listeners: MapSet.new(), event: %Event{}, line_part: ""
  end

  ## Client API

  @doc """
  Starts a new SSEParser.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Feeds some input data into the parser.
  """
  def feed_data(server, data) do
    GenServer.call(server, {:feed_data, data})
  end

  @doc """
  Registers a listener process to receive parsed events.
  """
  def register_listener(server, pid) do
    GenServer.call(server, {:register_listener, pid})
  end

  @doc """
  Unregisters a listener process.
  """
  def unregister_listener(server, pid) do
    GenServer.call(server, {:unregister_listener, pid})
  end

  ## Server callbacks

  def init(:ok) do
    {:ok, %State{}}
  end

  def handle_call({:feed_data, data}, _from, state) do
    new_state = data_received(data, state)
    {:reply, :ok, new_state}
  end

  def handle_call({:register_listener, pid}, _from, state) do
    new_listeners = MapSet.put(state.listeners, pid)
    {:reply, :ok, %{state | listeners: new_listeners}}
  end

  def handle_call({:unregister_listener, pid}, _from, state) do
    new_listeners = MapSet.delete(state.listeners, pid)
    {:reply, :ok, %{state | listeners: new_listeners}}
  end

  def handle_call(:_get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  ## Internals

  def emit_event(event, state) do
    Enum.each(state.listeners, fn l -> send(l, {:sse, event}) end)
  end

  ## Parser

  # This clause handles the end of the input.
  defp data_received("", state) do
    state
  end

  # These three clauses handle newlines.
  defp data_received("\r\n" <> data, state), do: line_complete(data, state)
  defp data_received("\r" <> data, state), do: line_complete(data, state)
  defp data_received("\n" <> data, state), do: line_complete(data, state)
  # This clause handles anything not matched above, which is all non-newlines
  # characters.
  defp data_received(<<char, data::binary>>, state) do
    %State{line_part: line} = state
    new_state = %{state | line_part: line <> <<char>>}
    data_received(data, new_state)
  end

  defp line_complete(data, state) do
    new_state = line_received(state.line_part, %{state | line_part: ""})
    data_received(data, new_state)
  end

  # Handle an empty line, which indicates the end of an event.
  defp line_received("", state) do
    if state.event.data != "" do
      # Remove one trailing newline (if there is one).
      data = String.replace_suffix(state.event.data, "\n", "")
      emit_event(%{state.event | data: data}, state)
    end

    %{state | event: %Event{}}
  end

  # Handle a comment by ignoring it.
  defp line_received(":" <> _, state), do: state
  # Parse the line into the field and value for further processing.
  defp line_received(line, state) do
    {field, value} =
      case String.split(line, ":", parts: 2) do
        [field] -> {field, ""}
        [field, " " <> value] -> {field, value}
        [field, value] -> {field, value}
      end

    process_field(field, value, state)
  end

  # Append the data value to the data field with a trailing newline.
  defp process_field("data", value, state) do
    new_event = %{state.event | data: state.event.data <> value <> "\n"}
    %{state | event: new_event}
  end

  # Set the event field to the event value.
  defp process_field("event", value, state) do
    new_event = %{state.event | event: value}
    %{state | event: new_event}
  end

  # Set the id field to the id value if the value does not contain a NUL.
  defp process_field("id", value, state) do
    if String.contains?(value, <<0>>),
      do: state,
      else: %{state | event: %{state.event | id: value}}
  end

  # Ignore any other field.
  defp process_field(_field, _value, state), do: state
end
