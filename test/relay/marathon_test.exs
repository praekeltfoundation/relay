Code.require_file(Path.join([__DIR__, "..", "marathon_client", "marathon_client_helper.exs"]))

defmodule Relay.MarathonTest do
  use ExUnit.Case, async: false

  alias Relay.Marathon
  alias Relay.Resources.AppEndpoint
  alias Marathon.Store

  @test_app %{
    "id" => "/mc2",
    "backoffFactor" => 1.15,
    "backoffSeconds" => 1,
    "container" => %{
      "type" => "DOCKER",
      "docker" => %{
        "forcePullImage" => true,
        "image" => "praekeltfoundation/mc2:release-3.11.2",
        "parameters" => [
          %{
            "key" => "add-host",
            "value" => "servicehost:172.17.0.1"
          }
        ],
        "privileged" => false
      },
      "volumes" => [],
      "portMappings" => [
        %{
          "containerPort" => 80,
          "hostPort" => 0,
          "labels" => %{},
          "protocol" => "tcp",
          "servicePort" => 10003
        }
      ]
    },
    "cpus" => 0.1,
    "disk" => 0,
    "env" => %{
      "MESOS_MARATHON_HOST" => "http://master.mesos:8080",
      "DEBUG" => "False",
      "PROJECT_ROOT" => "/deploy/"
    },
    "executor" => "",
    "instances" => 1,
    "labels" => %{
      #      "MARATHON_ACME_0_DOMAIN" => "mc2.example.org",
      #      "HAPROXY_0_REDIRECT_TO_HTTPS" => "true",
      "HAPROXY_0_VHOST" => "mc2.example.org",
      "HAPROXY_GROUP" => "external"
    },
    "maxLaunchDelaySeconds" => 3600,
    "mem" => 256,
    "gpus" => 0,
    "networks" => [
      %{
        "mode" => "container/bridge"
      }
    ],
    "requirePorts" => false,
    "upgradeStrategy" => %{
      "maximumOverCapacity" => 1,
      "minimumHealthCapacity" => 1
    },
    "version" => "2017-11-09T08:43:59.89Z",
    "versionInfo" => %{
      "lastScalingAt" => "2017-11-09T08:43:59.89Z",
      "lastConfigChangeAt" => "2017-11-08T15:06:31.066Z"
    },
    "killSelection" => "YOUNGEST_FIRST",
    "unreachableStrategy" => %{
      "inactiveAfterSeconds" => 300,
      "expungeAfterSeconds" => 600
    },
    "tasksStaged" => 0,
    "tasksRunning" => 1,
    "tasksHealthy" => 0,
    "tasksUnhealthy" => 0,
    "deployments" => []
  }

  @test_task %{
    "ipAddresses" => [
      %{
        "ipAddress" => "172.17.0.9",
        "protocol" => "IPv4"
      }
    ],
    "stagedAt" => "2018-02-16T14:29:06.487Z",
    "state" => "TASK_RUNNING",
    "ports" => [
      15979
    ],
    "startedAt" => "2018-02-16T14:29:09.605Z",
    "version" => "2017-11-09T08:43:59.890Z",
    "id" => "mc2.be753491-1325-11e8-b5d6-4686525b33db",
    "appId" => "/mc2",
    "slaveId" => "d25be2a7-61ce-475f-8b07-d56400c8d744-S1",
    "host" => "10.70.4.100"
  }

  @test_api_post_event %{
    "clientIp" => "10.0.91.11",
    "uri" => "/v2/apps//jamie-event-test",
    "appDefinition" => %{
      "id" => "/jamie-event-test",
      "cmd" => "python -m http.server 8080",
      "args" => nil,
      "user" => nil,
      "env" => %{},
      "instances" => 1,
      "cpus" => 0.01,
      "mem" => 64,
      "disk" => 0,
      "gpus" => 0,
      "executor" => "",
      "constraints" => [],
      "uris" => [],
      "fetch" => [],
      "storeUrls" => [],
      "backoffSeconds" => 1,
      "backoffFactor" => 1.15,
      "maxLaunchDelaySeconds" => 3600,
      "container" => %{
        "type" => "DOCKER",
        "volumes" => [],
        "docker" => %{
          "image" => "python:3.7-rc-alpine3.7",
          "network" => "BRIDGE",
          "portMappings" => [
            %{
              "containerPort" => 8080,
              "hostPort" => 10013,
              "servicePort" => 10013,
              "protocol" => "tcp",
              "name" => "default",
              "labels" => %{}
            }
          ],
          "privileged" => false,
          "parameters" => [],
          "forcePullImage" => false
        }
      },
      "healthChecks" => [],
      "readinessChecks" => [],
      "dependencies" => [],
      "upgradeStrategy" => %{
        "minimumHealthCapacity" => 1,
        "maximumOverCapacity" => 1
      },
      "labels" => %{
        "HAPROXY_GROUP" => "external",
        "HAPROXY_0_VHOST" => "jamie-event-test.example.org"
      },
      "ipAddress" => nil,
      "version" => "2018-04-11T10:40:14.575Z",
      "residency" => nil,
      "secrets" => %{},
      "taskKillGracePeriodSeconds" => nil,
      "unreachableStrategy" => %{
        "inactiveAfterSeconds" => 300,
        "expungeAfterSeconds" => 600
      },
      "killSelection" => "YOUNGEST_FIRST",
      "acceptedResourceRoles" => [
        "*"
      ],
      "ports" => [
        10013
      ],
      "portDefinitions" => [
        %{
          "port" => 10013,
          "protocol" => "tcp",
          "name" => "default",
          "labels" => %{}
        }
      ],
      "requirePorts" => true,
      "versionInfo" => %{
        "lastScalingAt" => "2018-04-11T10:40:14.575Z",
        "lastConfigChangeAt" => "2018-04-11T10:40:14.575Z"
      }
    },
    "eventType" => "api_post_event",
    "timestamp" => "2018-04-11T10:40:15.908Z"
  }

  @test_app_terminated_event %{
    "appId" => "/jamie-event-test",
    "eventType" => "app_terminated_event",
    "timestamp" => "2018-04-11T12:11:33.521Z"
  }

  @test_status_update_event %{
    "slaveId" => "7e76e0e4-f16c-4d63-a629-dd05d137a223-S3",
    "taskId" => "jamie-event-test.b9e93830-3d74-11e8-a2a6-1653cd73b500",
    "taskStatus" => "TASK_RUNNING",
    "message" => "",
    "appId" => "/jamie-event-test",
    "host" => "10.0.91.102",
    "ipAddresses" => [
      %{
        "ipAddress" => "172.17.0.2",
        "protocol" => "IPv4"
      }
    ],
    "ports" => [
      10013
    ],
    "version" => "2018-04-11T10:40:14.575Z",
    "eventType" => "status_update_event",
    "timestamp" => "2018-04-11T10:40:19.428Z"
  }

  @test_app_endpoint %AppEndpoint{
    name: "/mc2_0",
    domains: ["mc2.example.org"],
    addresses: [{"10.70.4.100", 15979}]
  }
  @test_event_endpoint %AppEndpoint{
    name: "/jamie-event-test_0",
    domains: ["jamie-event-test.example.org"],
    addresses: [{"10.0.91.102", 10013}]
  }
  @test_event_endpoint_no_address %AppEndpoint{
    name: "/jamie-event-test_0",
    domains: ["jamie-event-test.example.org"],
    addresses: []
  }

  defmodule StubGenServer do
    use GenServer

    def start_link(pid), do: GenServer.start_link(__MODULE__, pid, name: StubGenServer)

    @impl GenServer
    def init(pid), do: {:ok, pid}

    @impl GenServer
    def handle_call(msg, _from, pid) do
      send(pid, msg)
      {:reply, :ok, pid}
    end
  end

  setup do
    TestHelpers.override_log_level(:warn)
    TestHelpers.setup_apps([:cowboy, :hackney])

    # Set up FakeMarathon
    {:ok, fm} = start_supervised(FakeMarathon)

    # Store the test app and task
    FakeMarathon.set_apps(fm, [@test_app])
    FakeMarathon.set_app_tasks(fm, @test_app["id"], [@test_task])

    # Configure the Marathon URL for the FakeMarathon
    marathon_config =
      :relay
      |> Application.fetch_env!(:marathon)
      |> Keyword.put(:urls, [FakeMarathon.base_url(fm)])

    TestHelpers.put_env(:relay, :marathon, marathon_config)

    {:ok, res} = start_supervised({StubGenServer, self()})
    {:ok, store} = start_supervised({Store, resources: res})
    {:ok, _marathon} = start_supervised({Marathon, store: store})

    %{fake_marathon: fm}
  end

  defp assert_receive_update(endpoints),
    do: assert_receive({:update_app_endpoints, _version, ^endpoints}, 100)

  defp refute_update, do: refute_receive({:update_app_endpoints, _, _}, 100)

  describe "api_post_event" do
    test "relevant app", %{fake_marathon: fm} do
      assert_receive_update([@test_app_endpoint])

      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))

      assert_receive_update([@test_event_endpoint_no_address, @test_app_endpoint])
    end

    test "irrelevant app", %{fake_marathon: fm} do
      assert_receive_update([@test_app_endpoint])

      # Clear the labels so the app is irrelevant
      app_definition =
        @test_api_post_event
        |> Map.get("appDefinition")
        |> Map.put("labels", %{})

      event_data =
        @test_api_post_event
        |> Map.put("appDefinition", app_definition)
        |> Poison.encode!()

      FakeMarathon.event(fm, "api_post_event", event_data)

      refute_update()
    end

    test "app becomes irrelevant", %{fake_marathon: fm} do
      assert_receive_update([@test_app_endpoint])

      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))
      assert_receive_update([@test_event_endpoint_no_address, @test_app_endpoint])

      # Clear the labels so the app is irrelevant
      app_definition =
        @test_api_post_event
        |> Map.get("appDefinition")
        |> Map.put("labels", %{})

      event_data =
        @test_api_post_event
        |> Map.put("appDefinition", app_definition)
        |> Poison.encode!()

      FakeMarathon.event(fm, "api_post_event", event_data)

      assert_receive_update([@test_app_endpoint])
    end
  end

  describe "app_terminated_event" do
    test "app removed", %{fake_marathon: fm} do
      assert_receive_update([@test_app_endpoint])

      # TODO: Should we be storing the tasks app some other way?
      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))
      # Clear the mailbox messages
      assert_receive_update([@test_event_endpoint_no_address, @test_app_endpoint])

      FakeMarathon.event(fm, "app_terminated_event", Poison.encode!(@test_app_terminated_event))

      assert_receive_update([@test_app_endpoint])
    end
  end

  describe "status_update_event" do
    test "non-terminal state, relevant task", %{fake_marathon: fm} do
      assert_receive_update([@test_app_endpoint])

      # TODO: Should we be storing the tasks app some other way?
      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))
      # Clear the mailbox messages
      assert_receive_update([@test_event_endpoint_no_address, @test_app_endpoint])

      FakeMarathon.event(fm, "status_update_event", Poison.encode!(@test_status_update_event))

      assert_receive_update([@test_event_endpoint, @test_app_endpoint])
    end

    test "non-terminal state, irrelevant task", %{fake_marathon: fm} do
      assert_receive_update([@test_app_endpoint])

      # Don't store the app
      FakeMarathon.event(fm, "status_update_event", Poison.encode!(@test_status_update_event))

      refute_update()
    end

    test "terminal state", %{fake_marathon: fm} do
      assert_receive_update([@test_app_endpoint])

      # TODO: Should we be storing the tasks app some other way?
      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))
      assert_receive_update([@test_event_endpoint_no_address, @test_app_endpoint])

      FakeMarathon.event(fm, "status_update_event", Poison.encode!(@test_status_update_event))
      assert_receive_update([@test_event_endpoint, @test_app_endpoint])

      event_data =
        @test_status_update_event
        |> Map.put("taskStatus", "TASK_KILLED")
        |> Poison.encode!()

      FakeMarathon.event(fm, "status_update_event", event_data)

      # Endpoint removed, same as if we just had app data
      assert_receive_update([@test_event_endpoint_no_address, @test_app_endpoint])
    end
  end

  test "irrelevant event", %{fake_marathon: fm} do
    assert_receive_update([@test_app_endpoint])

    event = %{
      "remoteAddress" => "10.0.91.9",
      "eventType" => "event_stream_attached",
      "timestamp" => "2018-04-11T11:45:47.417Z"
    }

    FakeMarathon.event(fm, "event_stream_attached", Poison.encode!(event))

    refute_update()
  end
end
