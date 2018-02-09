Code.require_file(Path.join([__DIR__, "marathon_client_helper.exs"]))

defmodule Relay.MarathonClientTest do
  use ExUnit.Case

  alias Relay.MarathonClient
  import MarathonTestHelpers, only: [
    marathon_event: 2,
    setup_apps: 0,
    cleanup_apps: 1,
  ]

  setup_all do
    apps = setup_apps()
    on_exit(fn -> cleanup_apps(apps) end)
  end

  test "watch marathon events" do
    {:ok, fm} = start_supervised(FakeMarathon)
    {:ok, _} = MarathonClient.stream_events(FakeMarathon.base_url(fm), [self()])

    # Stream an event, assert that we receive it within a second.
    event = marathon_event("event_stream_attached", remoteAddress: "127.0.0.1")
    FakeMarathon.event(fm, event.event, event.data)
    assert_receive {:sse, ^event}, 1_000

    # Stream and assert on another event.
    event2 = marathon_event("event_stream_attached", remoteAddress: "10.1.2.3")
    FakeMarathon.event(fm, event2.event, event2.data)
    assert_receive {:sse, ^event2}, 1_000
  end
end
