Code.require_file(Path.join([__DIR__, "marathon_client_helper.exs"]))

defmodule Relay.MarathonClient.SSEClientTest do
  use ExUnit.Case

  alias Relay.MarathonClient.SSEClient
  import MarathonTestHelpers, only: [
    marathon_event: 2,
    setup_apps: 0,
    cleanup_apps: 1,
  ]

  setup_all do
    apps = setup_apps()
    on_exit(fn -> cleanup_apps(apps) end)
  end

  def stream_events(fm, timeout \\ 60_000) do
    url = FakeMarathon.base_url(fm) <> "/v2/events"
    SSEClient.start_link({url, [self()], timeout})
  end

  test "the SSE client streams events to a listener process" do
    {:ok, fm} = start_supervised(FakeMarathon)
    {:ok, _} = stream_events(fm)

    # Stream an event, assert that we receive it within a second.
    event = marathon_event("event_stream_attached", remoteAddress: "127.0.0.1")
    FakeMarathon.event(fm, event.event, event.data)
    assert_receive {:sse, ^event}, 1_000

    # Stream and assert on another event.
    event2 = marathon_event("event_stream_attached", remoteAddress: "10.1.2.3")
    FakeMarathon.event(fm, event2.event, event2.data)
    assert_receive {:sse, ^event2}, 1_000
  end

  test "the SSE client exits when the server connection is closed" do
    {:ok, fm} = start_supervised(FakeMarathon)
    {:ok, se} = stream_events(fm)
    ref = Process.monitor(se)

    # Stream an event, assert that we receive it within a second.
    event = marathon_event("event_stream_attached", remoteAddress: "127.0.0.1")
    FakeMarathon.event(fm, event.event, event.data)
    assert_receive {:sse, ^event}, 1_000

    # Close the connection on the server side.
    FakeMarathon.end_stream(fm)
    assert_receive {:DOWN, ^ref, :process, _, :normal}, 1_000
  end

  test "the SSE client fails on a bad response" do
    # Trap exits so the start_link in stream_events doesn't break the test.
    Process.flag(:trap_exit, true)
    {:ok, fm} = start_supervised(FakeMarathon)
    base_url = FakeMarathon.base_url(fm)
    {:error, err} = SSEClient.start_link({base_url <> "/bad", [self()], 60_000})
    assert err =~ ~r/Error connecting to event stream: .*{code: 404/
  end

  test "the SSE client only starts once a response is received" do
    # On my machine, without waiting for the response, the delay is
    # consistently under 100ms. I chose 250ms here as a balance between
    # incorrect results and waiting too long.
    delay_ms = 250

    {:ok, fm} = start_supervised({FakeMarathon, [response_delay: delay_ms]})
    t0 = Time.utc_now()
    {:ok, _} = stream_events(fm)
    t1 = Time.utc_now()
    assert Time.diff(t1, t0, :milliseconds) >= delay_ms

    # Stream an event, assert that we receive it within a second.
    event = marathon_event("event_stream_attached", remoteAddress: "127.0.0.1")
    FakeMarathon.event(fm, event.event, event.data)
    assert_receive {:sse, ^event}, 1_000
  end

  test "the SSE client times out if no data is received for too long" do
    # Trap exits so the start_link in stream_events doesn't break the test.
    Process.flag(:trap_exit, true)
    {:ok, fm} = start_supervised(FakeMarathon)
    {:ok, sc} = stream_events(fm, 100)
    ref = Process.monitor(sc)

    # Send keepalives for longer than our timeout interval.
    FakeMarathon.keepalive(fm)
    Process.sleep(50)
    FakeMarathon.keepalive(fm)
    Process.sleep(50)
    FakeMarathon.keepalive(fm)

    # Stream an event, assert that we receive it within a second.
    event = marathon_event("event_stream_attached", remoteAddress: "127.0.0.1")
    FakeMarathon.event(fm, event.event, event.data)
    assert_receive {:sse, ^event}, 1_000

    # Capture the error that gets logged outside our control.
    import ExUnit.CaptureLog
    assert capture_log(fn ->
      # Wait for the timeout.
      assert_receive {:DOWN, ^ref, :process, _, {:closed, :timeout}}, 150
    end) =~ ~r/\[error\] .* terminating\n\*\* \(stop\) \{:closed, :timeout\}/
  end
end
