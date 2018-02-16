Code.require_file(Path.join([__DIR__, "marathon_client_helper.exs"]))

defmodule MarathonClient.SSEParserTest do
  use ExUnit.Case, async: true

  alias MarathonClient.SSEParser
  alias SSEParser.{Event, State}

  setup do
    {:ok, ssep} = start_supervised(SSEParser)
    %{ssep: ssep}
  end

  def get_state(ssep) do
    {:ok, state} = GenServer.call(ssep, :_get_state)
    state
  end

  def estr(event), do: "#{event}"

  test "events are printable" do
    assert estr(%Event{}) == ~s'#Event< "" id="">'
    assert estr(%Event{id: "3"}) == ~s'#Event< "" id="3">'
    assert estr(%Event{event: "dinner"}) == ~s'#Event<dinner "" id="">'
    assert estr(%Event{data: "food"}) == ~s'#Event< "food" id="">'
    assert estr(%Event{event: "dinner", data: "food", id: "3"}) ==
      ~s'#Event<dinner "food" id="3">'
  end

  test "register_listener is idempotent", %{ssep: ssep} do
    assert get_state(ssep) == %State{listeners: MapSet.new()}
    assert SSEParser.register_listener(ssep, self()) == :ok
    assert get_state(ssep) == %State{listeners: MapSet.new([self()])}
    assert SSEParser.register_listener(ssep, self()) == :ok
    assert get_state(ssep) == %State{listeners: MapSet.new([self()])}
  end

  test "unregister_listener is idempotent", %{ssep: ssep} do
    assert SSEParser.register_listener(ssep, self()) == :ok
    assert get_state(ssep) == %State{listeners: MapSet.new([self()])}
    assert SSEParser.unregister_listener(ssep, self()) == :ok
    assert get_state(ssep) == %State{listeners: MapSet.new()}
    assert SSEParser.unregister_listener(ssep, self()) == :ok
    assert get_state(ssep) == %State{listeners: MapSet.new()}
  end

  test "empty events are not sent", %{ssep: ssep} do
    {:ok, listener} = start_supervised(EventCatcher)
    assert SSEParser.register_listener(ssep, listener) == :ok
    assert EventCatcher.events(listener) == []
    assert SSEParser.feed_data(ssep, "\n\n") == :ok
    assert get_state(ssep).event == %Event{}
    assert EventCatcher.events(listener) == []
    assert SSEParser.feed_data(ssep, "data: hello\n\n") == :ok
    assert get_state(ssep).event == %Event{}
    assert EventCatcher.events(listener) == [%Event{data: "hello"}]
  end

  test "a listener receives events", %{ssep: ssep} do
    {:ok, listener} = start_supervised(EventCatcher)
    assert SSEParser.register_listener(ssep, listener) == :ok
    assert EventCatcher.events(listener) == []
    assert SSEParser.feed_data(ssep, "data: hello\n\n") == :ok
    assert get_state(ssep).event == %Event{}
    assert EventCatcher.events(listener) == [%Event{data: "hello"}]
  end

  test "multiple listeners receive events", %{ssep: ssep} do
    {:ok, l1} = start_supervised(EventCatcher, id: :l1)
    {:ok, l2} = start_supervised(EventCatcher, id: :l2)
    assert SSEParser.register_listener(ssep, l1) == :ok
    assert SSEParser.register_listener(ssep, l2) == :ok
    assert SSEParser.feed_data(ssep, "data: sanibonani\n\n") == :ok
    assert EventCatcher.events(l1) == [%Event{data: "sanibonani"}]
    assert EventCatcher.events(l2) == [%Event{data: "sanibonani"}]
  end

  test "partial lines are buffered", %{ssep: ssep} do
    assert SSEParser.feed_data(ssep, "data: hello") == :ok
    assert get_state(ssep) == %State{event: %Event{}, line_part: "data: hello"}
    assert SSEParser.feed_data(ssep, " ") == :ok
    assert SSEParser.feed_data(ssep, "world\n") == :ok
    assert get_state(ssep) == %State{event: %Event{data: "hello world\n"}}
  end

  test "comments are ignored", %{ssep: ssep} do
    assert SSEParser.feed_data(ssep, ":hello") == :ok
    assert get_state(ssep) == %State{event: %Event{}, line_part: ":hello"}
    assert SSEParser.feed_data(ssep, "\n") == :ok
    assert get_state(ssep) == %State{event: %Event{}, line_part: ""}
  end

  test "unknown fields are ignored", %{ssep: ssep} do
    assert SSEParser.feed_data(ssep, "hello:") == :ok
    assert get_state(ssep) == %State{event: %Event{}, line_part: "hello:"}
    assert SSEParser.feed_data(ssep, " world\n") == :ok
    assert get_state(ssep) == %State{event: %Event{}, line_part: ""}
  end

  test "data field is appended to", %{ssep: ssep} do
    assert SSEParser.feed_data(ssep, "data: line 1\n") == :ok
    assert get_state(ssep) == %State{event: %Event{data: "line 1\n"}}
    assert SSEParser.feed_data(ssep, "data: line 2\n") == :ok
    assert get_state(ssep) == %State{event: %Event{data: "line 1\nline 2\n"}}
  end

  test "event field is replaced", %{ssep: ssep} do
    assert SSEParser.feed_data(ssep, "event: sad\n") == :ok
    assert get_state(ssep) == %State{event: %Event{event: "sad"}}
    assert SSEParser.feed_data(ssep, "event: happy\n") == :ok
    assert get_state(ssep) == %State{event: %Event{event: "happy"}}
  end

  test "id field is replaced", %{ssep: ssep} do
    assert SSEParser.feed_data(ssep, "id: 1\n") == :ok
    assert get_state(ssep) == %State{event: %Event{id: "1"}}
    assert SSEParser.feed_data(ssep, "id: 2\n") == :ok
    assert get_state(ssep) == %State{event: %Event{id: "2"}}
  end

  test "id field containing NUL is ignored", %{ssep: ssep} do
    assert SSEParser.feed_data(ssep, "id: 1\n") == :ok
    assert get_state(ssep) == %State{event: %Event{id: "1"}}
    assert SSEParser.feed_data(ssep, "id: 2\x00\n") == :ok
    assert get_state(ssep) == %State{event: %Event{id: "1"}}
  end

  test "field value containing colon is properly handled", %{ssep: ssep} do
    assert SSEParser.feed_data(ssep, "data: 16:9\n") == :ok
    assert get_state(ssep) == %State{event: %Event{data: "16:9\n"}}
  end

end
