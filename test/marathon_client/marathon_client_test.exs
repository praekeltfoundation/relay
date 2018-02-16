Code.require_file(Path.join([__DIR__, "marathon_client_helper.exs"]))

defmodule Relay.MarathonClientTest do
  use ExUnit.Case

  alias MarathonClient
  import MarathonTestHelpers, only: [marathon_event: 2]

  setup_all do
    TestHelpers.override_log_level(:info)
    TestHelpers.setup_apps([:cowboy, :hackney])
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

  test "get marathon apps" do
    app = %{
      "id" => "/product/us-east/service/myapp",
      "cmd" => "env && sleep 60",
      "constraints" => [["hostname", "UNIQUE", ""]],
      "container" => nil,
      "cpus" => 0.1,
      "env" => %{"LD_LIBRARY_PATH" => "/usr/local/lib/myLib"},
      "executor" => "",
      "instances" => 3,
      "mem" => 5.0,
      "ports" => [15092, 14566],
      "tasksRunning" => 0,
      "tasksStaged" => 1,
      "uris" => [
        "https://raw.github.com/mesosphere/marathon/master/README.md"
      ],
      "version" => "2014-03-01T23:42:20.938Z"
    }

    {:ok, fm} = start_supervised(FakeMarathon)
    base_url = FakeMarathon.base_url(fm)
    assert {:ok, %{"apps" => []}} == MarathonClient.get_apps(base_url)

    :ok = FakeMarathon.set_apps(fm, [app])
    assert {:ok, %{"apps" => [app]}} == MarathonClient.get_apps(base_url)
  end
end
