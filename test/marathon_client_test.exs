Code.require_file(Path.join([__DIR__, "marathon_client", "marathon_client_helper.exs"]))

defmodule MarathonClientTest do
  use ExUnit.Case

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

  describe "/v2/apps" do
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

    test "embed app tasks" do
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

      task = %{
        "appId" => "/product/us-east/service/myapp",
        "host" => "srv7.hw.ca1.mesosphere.com",
        "id" => "product_us-east_service_myapp.564bd685-4c30-11e5-98c1-be5b2935a987",
        "ports" => [
          31756
        ],
        "slaveId" => nil,
        "stagedAt" => "2015-08-26T20:23:39.463Z",
        "startedAt" => "2015-08-26T20:23:44.678Z",
        "version" => "2015-04-17T04:00:14.171Z"
      }

      {:ok, fm} = start_supervised(FakeMarathon)
      base_url = FakeMarathon.base_url(fm)

      :ok = FakeMarathon.set_apps(fm, [app])
      :ok = FakeMarathon.set_app_tasks(fm, app["id"], [task])

      expected_app = Map.put(app, "tasks", [task])

      assert {:ok, %{"apps" => [expected_app]}} ==
               MarathonClient.get_apps(base_url, embed: ["apps.tasks"])
    end
  end

  describe "/v2/apps/{app_id}/tasks" do
    test "get tasks" do
      task = %{
        "appId" => "/minecraft",
        "host" => "srv7.hw.ca1.mesosphere.com",
        "id" => "minecraft_survival-world.564bd685-4c30-11e5-98c1-be5b2935a987",
        "ports" => [
          31756
        ],
        "slaveId" => nil,
        "stagedAt" => "2015-08-26T20:23:39.463Z",
        "startedAt" => "2015-08-26T20:23:44.678Z",
        "version" => "2015-04-17T04:00:14.171Z"
      }

      {:ok, fm} = start_supervised(FakeMarathon)
      base_url = FakeMarathon.base_url(fm)

      :ok = FakeMarathon.set_app_tasks(fm, "/minecraft", [task])

      assert {:ok, %{"tasks" => [task]}} == MarathonClient.get_app_tasks(base_url, "/minecraft")
    end

    test "app not found" do
      {:ok, fm} = start_supervised(FakeMarathon)
      base_url = FakeMarathon.base_url(fm)

      assert {:error, {404, %{"message" => "App '/minecraft' does not exist"}}} ==
               MarathonClient.get_app_tasks(base_url, "/minecraft")
    end

    test "app_ids with and without leading/trailing /'s supported" do
      task = %{
        "appId" => "/minecraft",
        "host" => "srv7.hw.ca1.mesosphere.com",
        "id" => "minecraft_survival-world.564bd685-4c30-11e5-98c1-be5b2935a987",
        "ports" => [
          31756
        ],
        "slaveId" => nil,
        "stagedAt" => "2015-08-26T20:23:39.463Z",
        "startedAt" => "2015-08-26T20:23:44.678Z",
        "version" => "2015-04-17T04:00:14.171Z"
      }

      {:ok, fm} = start_supervised(FakeMarathon)
      base_url = FakeMarathon.base_url(fm)

      :ok = FakeMarathon.set_app_tasks(fm, "/minecraft", [task])

      assert {:ok, %{"tasks" => [task]}} == MarathonClient.get_app_tasks(base_url, "/minecraft")
      assert {:ok, %{"tasks" => [task]}} == MarathonClient.get_app_tasks(base_url, "minecraft")
      assert {:ok, %{"tasks" => [task]}} == MarathonClient.get_app_tasks(base_url, "minecraft/")
      assert {:ok, %{"tasks" => [task]}} == MarathonClient.get_app_tasks(base_url, "/minecraft/")
    end
  end
end
