defmodule Relay.MarathonTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.{App, Task}

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
      "PROJECT_ROOT" => "/deploy/",
    },
    "executor" => "",
    "instances" => 1,
    "labels" => %{
      "MARATHON_ACME_0_DOMAIN" => "mc2.example.org",
      "HAPROXY_0_REDIRECT_TO_HTTPS" => "true",
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

  describe "Marathon.App" do
    test "app from definition" do
      assert App.from_definition(@test_app) == %App{
        id: "/mc2",
        labels: %{
          "HAPROXY_0_REDIRECT_TO_HTTPS" => "true",
          "HAPROXY_0_VHOST" => "mc2.example.org",
          "HAPROXY_GROUP" => "external",
          "MARATHON_ACME_0_DOMAIN" => "mc2.example.org"
        },
        networking_mode: :"container/bridge",
        ports_list: [80],
        version: "2017-11-08T15:06:31.066Z"
      }
    end

    test "app port indices in group" do
      app = App.from_definition(@test_app)

      assert App.port_indices_in_group(app, "internal") == []
      assert App.port_indices_in_group(app, "external") == [0]
    end

    test "app label getters" do
      app = App.from_definition(@test_app)

      assert App.marathon_lb_vhost(app, 0) == ["mc2.example.org"]
      assert App.marathon_lb_vhost(app, 1) == []

      assert App.marathon_lb_redirect_to_https?(app, 0)
      assert not App.marathon_lb_redirect_to_https?(app, 1)

      assert App.marathon_acme_domain(app, 0) == ["mc2.example.org"]
      assert App.marathon_acme_domain(app, 1) == []
    end
  end

  describe "Marathon.Task" do
    test "task from definition" do
      app = App.from_definition(@test_app)

      assert Task.from_definition(app, @test_task) == %Task{
        address: "10.70.4.100",
        app_id: "/mc2",
        id: "mc2.be753491-1325-11e8-b5d6-4686525b33db",
        ports: [15979],
        version: "2017-11-09T08:43:59.890Z"
      }
    end

    test "task from definition container networking" do
      app =
        @test_app
        |> Map.put("networks", [%{"mode" => "container", "name" => "dcos"}])
        |> App.from_definition()

      assert Task.from_definition(app, @test_task) == %Task{
        address: "172.17.0.9",
        app_id: "/mc2",
        id: "mc2.be753491-1325-11e8-b5d6-4686525b33db",
        ports: [80],
        version: "2017-11-09T08:43:59.890Z"
      }
    end

    test "task port" do
      task = Task.from_definition(App.from_definition(@test_app), @test_task)

      assert Task.endpoint(task, 0) == {"10.70.4.100", 15979}
    end
  end
end
