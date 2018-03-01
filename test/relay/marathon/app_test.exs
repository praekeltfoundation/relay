defmodule Relay.Marathon.AppTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.App

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

  test "from definition" do
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


  test "port indices in group" do
    app = App.from_definition(@test_app)

    assert App.port_indices_in_group(app, "internal") == []
    assert App.port_indices_in_group(app, "external") == [0]
  end

  test "label getters" do
    app = App.from_definition(@test_app)

    assert App.marathon_lb_vhost(app, 0) == ["mc2.example.org"]
    assert App.marathon_lb_vhost(app, 1) == []

    assert App.marathon_lb_redirect_to_https?(app, 0)
    assert not App.marathon_lb_redirect_to_https?(app, 1)

    assert App.marathon_acme_domain(app, 0) == ["mc2.example.org"]
    assert App.marathon_acme_domain(app, 1) == []
  end
end
