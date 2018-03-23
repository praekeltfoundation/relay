defmodule Relay.Marathon.NetworkingTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.Networking

  @test_app %{
    "id" => "/foovu1",
    "cmd" => "python -m http.server 8080",
    "args" => nil,
    "user" => nil,
    "env" => %{},
    "instances" => 1,
    "cpus" => 0.1,
    "mem" => 32,
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
    "container" => nil,
    "healthChecks" => [],
    "readinessChecks" => [],
    "dependencies" => [],
    "upgradeStrategy" => %{
      "minimumHealthCapacity" => 1,
      "maximumOverCapacity" => 1
    },
    "labels" => %{},
    "ipAddress" => nil,
    "version" => "2017-05-22T08:53:15.476Z",
    "residency" => nil,
    "secrets" => %{},
    "taskKillGracePeriodSeconds" => nil,
    "unreachableStrategy" => %{
      "inactiveAfterSeconds" => 300,
      "expungeAfterSeconds" => 600
    },
    "killSelection" => "YOUNGEST_FIRST",
    "versionInfo" => %{
      "lastScalingAt" => "2017-05-22T08:53:15.476Z",
      "lastConfigChangeAt" => "2017-05-22T08:53:15.476Z"
    },
    "tasksStaged" => 0,
    "tasksRunning" => 1,
    "tasksHealthy" => 0,
    "tasksUnhealthy" => 0,
    "deployments" => []
  }

  describe "networking_mode/1" do
    test "host networking mode (Marathon 1.5+)" do
      app = @test_app |> Map.put("networks", [%{"mode" => "host"}])

      assert Networking.networking_mode(app) == :host
    end

    test "container networking mode (Marathon 1.5+)" do
      app = @test_app |> Map.put("networks", [%{"mode" => "container", "name" => "dcos"}])

      assert Networking.networking_mode(app) == :container
    end

    test "container/bridge networking mode (Marathon 1.5+)" do
      app = @test_app |> Map.put("networks", [%{"mode" => "container/bridge"}])

      assert Networking.networking_mode(app) == :"container/bridge"
    end

    test "host networking with Docker container (Marathon < 1.5)" do
      app =
        @test_app
        |> Map.put("container", %{
          "type" => "DOCKER",
          "volumes" => [],
          "docker" => %{
            "image" => "praekeltfoundation/marathon-lb:1.6.0",
            "network" => "HOST",
            "portMappings" => [],
            "privileged" => true,
            "parameters" => [],
            "forcePullImage" => false
          }
        })

      assert Networking.networking_mode(app) == :host
    end

    test "host networking with Docker container w/o network (Marathon < 1.5)" do
      # At least with DC/OS 1.9, container.docker.network seems to always be
      # null with host networking.
      app =
        @test_app
        |> Map.put("container", %{
          "type" => "DOCKER",
          "volumes" => [],
          "docker" => %{
            "image" => "python:3-alpine3.7",
            "network" => nil,
            "portMappings" => [],
            "privileged" => false,
            "parameters" => [],
            "forcePullImage" => false
          }
        })

      assert Networking.networking_mode(app) == :host
    end

    test "container/bridge networking with Docker container (Marathon < 1.5)" do
      app =
        @test_app
        |> Map.put("container", %{
          "type" => "DOCKER",
          "volumes" => [],
          "docker" => %{
            "image" => "index.docker.io/jerithorg/testapp:0.0.12",
            "network" => "BRIDGE",
            "portMappings" => [
              %{
                "containerPort" => 5858,
                "hostPort" => 0,
                "servicePort" => 10008,
                "protocol" => "tcp",
                "labels" => %{}
              }
            ],
            "privileged" => false,
            "parameters" => [],
            "forcePullImage" => true
          }
        })

      assert Networking.networking_mode(app) == :"container/bridge"
    end

    test "container networking with Docker container (Marathon < 1.5)" do
      app =
        @test_app
        |> Map.put("container", %{
          "type" => "DOCKER",
          "volumes" => [],
          "docker" => %{
            "image" => "python:3-alpine",
            "network" => "USER",
            "portMappings" => [
              %{
                "containerPort" => 8080,
                "servicePort" => 10004,
                "protocol" => "tcp",
                "name" => "foovu1http",
                "labels" => %{
                  "VIP_0" => "/foovu1:8080"
                }
              }
            ],
            "privileged" => false,
            "parameters" => [],
            "forcePullImage" => false
          }
        })

      assert Networking.networking_mode(app) == :container
    end

    test "legacy IP-per-task (Marathon < 1.5)" do
      app =
        @test_app
        |> Map.put("ipAddress", %{
          "groups" => [],
          "labels" => %{},
          "discovery" => %{
            "ports" => [
              %{"number" => 80, "name" => "http", "protocol" => "tcp"},
              %{"number" => 443, "name" => "http", "protocol" => "tcp"}
            ]
          }
        })

      assert Networking.networking_mode(app) == :container
    end

    test "host networking (Marathon < 1.5)" do
      app =
        @test_app
        |> Map.put("portDefinitions", [
          %{
            "port" => 10008,
            "protocol" => "tcp",
            "name" => "default",
            "labels" => %{}
          }
        ])

      assert Networking.networking_mode(app) == :host
    end
  end

  describe "ports_list/1" do
    test "host networking" do
      app =
        @test_app
        |> Map.put("networks", [%{"mode" => "host"}])
        |> Map.put("portDefinitions", [
          %{
            "port" => 10008,
            "protocol" => "tcp",
            "name" => "default",
            "labels" => %{}
          }
        ])

      assert Networking.ports_list(app) == [10008]
    end

    test "container/bridge networking (Marathon 1.5+)" do
      app =
        @test_app
        |> Map.put("networks", [%{"mode" => "container/bridge"}])
        |> Map.put("container", %{
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
              "servicePort" => 10005
            }
          ]
        })

      assert Networking.ports_list(app) == [80]
    end

    test "container/bridge networking Mesos containerizer (Marathon 1.5+)" do
      app =
        @test_app
        |> Map.put("networks", [%{"mode" => "container/bridge"}])
        |> Map.put("container", %{
          "type" => "MESOS",
          "docker" => %{
            "image" => "my-image:1.0"
          },
          "portMappings" => [
            %{"containerPort" => 80, "hostPort" => 0, "name" => "http"},
            %{"containerPort" => 443, "hostPort" => 0, "name" => "https"},
            %{"containerPort" => 4000, "hostPort" => 0, "name" => "mon"}
          ]
        })

      assert Networking.ports_list(app) == [80, 443, 4000]
    end

    test "container networking (Marathon 1.5+)" do
      app =
        @test_app
        |> Map.put("networks", [%{"mode" => "container", "name" => "dcos"}])
        |> Map.put("container", %{
          "type" => "DOCKER",
          "docker" => %{
            "forcePullImage" => false,
            "image" => "python:3-alpine",
            "parameters" => [],
            "privileged" => false
          },
          "volumes" => [],
          "portMappings" => [
            %{
              "containerPort" => 8080,
              "labels" => %{
                "VIP_0" => "/foovu1:8080"
              },
              "name" => "foovu1http",
              "protocol" => "tcp",
              "servicePort" => 10004
            }
          ]
        })

      assert Networking.ports_list(app) == [8080]
    end

    test "container networking (Marathon < 1.5)" do
      app =
        @test_app
        |> Map.put("container", %{
          "type" => "DOCKER",
          "volumes" => [],
          "docker" => %{
            "image" => "python:3-alpine",
            "network" => "USER",
            "portMappings" => [
              %{
                "containerPort" => 8080,
                "servicePort" => 10004,
                "protocol" => "tcp",
                "name" => "foovu1http",
                "labels" => %{
                  "VIP_0" => "/foovu1:8080"
                }
              }
            ],
            "privileged" => false,
            "parameters" => [],
            "forcePullImage" => false
          }
        })

      assert Networking.ports_list(app) == [8080]
    end

    test "IP-per-task (Marathon < 1.5)" do
      app =
        @test_app
        |> Map.put("ipAddress", %{
          "groups" => [],
          "labels" => %{},
          "discovery" => %{
            "ports" => [
              %{"number" => 80, "name" => "http", "protocol" => "tcp"},
              %{"number" => 443, "name" => "http", "protocol" => "tcp"}
            ]
          }
        })

      assert Networking.ports_list(app) == [80, 443]
    end

    test "bridge networking (Marathon < 1.5)" do
      app =
        @test_app
        |> Map.put("container", %{
          "type" => "DOCKER",
          "volumes" => [],
          "docker" => %{
            "image" => "index.docker.io/jerithorg/testapp:0.0.12",
            "network" => "BRIDGE",
            "portMappings" => [
              %{
                "containerPort" => 5858,
                "hostPort" => 0,
                "servicePort" => 10008,
                "protocol" => "tcp",
                "labels" => %{}
              }
            ],
            "privileged" => false,
            "parameters" => [],
            "forcePullImage" => true
          }
        })

      assert Networking.ports_list(app) == [5858]
    end
  end

  @test_task %{
    "stagedAt" => "2018-02-15T00:19:09.174Z",
    "state" => "TASK_RUNNING",
    "startedAt" => "2018-02-15T00:19:40.911Z",
    "version" => "2017-09-29T09:51:28.863Z",
    "id" => "dcos-ingress.d7470966-11e5-11e8-a2a6-1653cd73b500",
    "appId" => "/dcos-ingress",
    "slaveId" => "7e76e0e4-f16c-4d63-a629-dd05d137a223-S4",
    "servicePorts" => [
      10008
    ]
  }

  describe "task_address/2" do
    test "host networking" do
      task = @test_task |> Map.put("host", "10.0.91.103")

      assert Networking.task_address(:host, task) == "10.0.91.103"
    end

    test "container/bridge networking" do
      task = @test_task |> Map.put("host", "10.0.91.103")

      assert Networking.task_address(:"container/bridge", task) == "10.0.91.103"
    end

    test "container networking" do
      task =
        @test_task
        |> Map.put("ipAddresses", [
          %{
            "ipAddress" => "9.0.4.130",
            "protocol" => "IPv4"
          }
        ])

      assert Networking.task_address(:container, task) == "9.0.4.130"
    end
  end

  describe "task_ports/2" do
    test "host networking" do
      task = @test_task |> Map.put("ports", [31791])

      assert Networking.task_ports(:host, task) == [31791]
    end

    test "container/bridge networking" do
      task = @test_task |> Map.put("ports", [31791])

      assert Networking.task_ports(:"container/bridge", task) == [31791]
    end

    test "container networking" do
      task = @test_task

      assert Networking.task_ports(:container, task) == nil
    end
  end
end
