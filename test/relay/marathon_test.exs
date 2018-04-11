Code.require_file(Path.join([__DIR__, "..", "marathon_client", "marathon_client_helper.exs"]))

defmodule Relay.MarathonTest do
  use ExUnit.Case, async: false

  alias Relay.{Publisher, Marathon, Resources}
  alias Marathon.Store

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

  setup do
    TestHelpers.override_log_level(:warn)
    TestHelpers.setup_apps([:cowboy, :hackney])

    # Set up FakeMarathon and configure it as the Marathon URL
    {:ok, fm} = start_supervised(FakeMarathon)

    marathon_config =
      :relay
      |> Application.fetch_env!(:marathon)
      |> Keyword.put(:urls, [FakeMarathon.base_url(fm)])

    TestHelpers.put_env(:relay, :marathon, marathon_config)

    {:ok, pub} = start_supervised(Publisher)
    # Subscribe to the Publisher so that we can check when it gets updated
    for xds <- [:rds, :cds, :eds] do
      Publisher.subscribe(pub, xds, self())
      # Ignore the empty state message
      receive do
        {^xds, _, _} -> :ok
      end
    end

    {:ok, res} = start_supervised({Resources, publisher: pub})
    {:ok, store} = start_supervised({Store, resources: res})
    {:ok, _marathon} = start_supervised({Marathon, store: store})

    %{fake_marathon: fm}
  end

  defp assert_receive_clusters do
    alias Envoy.Api.V2.Cluster
    assert_receive {:cds, _version, [%Cluster{name: "/jamie-event-test_0"}]}, 100
  end

  defp assert_receive_routes do
    alias Envoy.Api.V2.RouteConfiguration
    alias Envoy.Api.V2.Route.{Route, RouteAction, RouteMatch, VirtualHost}

    assert_receive {
                     :rds,
                     _version,
                     [
                       %RouteConfiguration{
                         name: "http",
                         virtual_hosts: [
                           %VirtualHost{
                             domains: ["jamie-event-test.example.org"],
                             routes: [
                               %Route{
                                 action:
                                   {:route,
                                    %RouteAction{
                                      cluster_specifier: {:cluster, "/jamie-event-test_0"}
                                    }},
                                 match: %RouteMatch{path_specifier: {:prefix, "/"}}
                               }
                             ]
                           }
                         ]
                       },
                       %RouteConfiguration{
                         name: "https",
                         virtual_hosts: [
                           %VirtualHost{
                             domains: ["jamie-event-test.example.org"],
                             routes: [
                               %Route{
                                 action:
                                   {:route,
                                    %RouteAction{
                                      cluster_specifier: {:cluster, "/jamie-event-test_0"}
                                    }},
                                 match: %RouteMatch{path_specifier: {:prefix, "/"}}
                               }
                             ]
                           }
                         ]
                       }
                     ]
                   },
                   100
  end

  defp assert_receive_endpoints_empty do
    alias Envoy.Api.V2.ClusterLoadAssignment
    alias Envoy.Api.V2.Endpoint.LocalityLbEndpoints

    assert_receive {:eds, _version,
                    [
                      %ClusterLoadAssignment{
                        cluster_name: "/jamie-event-test_0",
                        endpoints: [%LocalityLbEndpoints{lb_endpoints: []}]
                      }
                    ]},
                   100
  end

  defp assert_receive_endpoints do
    alias Envoy.Api.V2.ClusterLoadAssignment
    alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}
    alias Envoy.Api.V2.Core.{Address, SocketAddress}

    assert_receive {:eds, _version,
                    [
                      %ClusterLoadAssignment{
                        cluster_name: "/jamie-event-test_0",
                        endpoints: [
                          %LocalityLbEndpoints{
                            lb_endpoints: [
                              %LbEndpoint{
                                endpoint: %Endpoint{
                                  address: %Address{
                                    address:
                                      {:socket_address,
                                       %SocketAddress{
                                         address: "10.0.91.102",
                                         port_specifier: {:port_value, 10013}
                                       }}
                                  }
                                }
                              }
                            ]
                          }
                        ]
                      }
                    ]},
                   100
  end

  defp assert_app_updates do
    # Assert we receive RDS, CDS, & EDS messages but without any endpoints
    assert_receive_routes()
    assert_receive_clusters()
    assert_receive_endpoints_empty()
  end

  defp assert_task_updates do
    # Assert we receive RDS, CDS, & EDS messages but with endpoints this time
    assert_receive_routes()
    assert_receive_clusters()
    assert_receive_endpoints()
  end

  defp refute_updates do
    refute_receive {:rds, _, _}, 100
    refute_receive {:cds, _, _}, 100
    refute_receive {:eds, _, _}, 100
  end

  describe "api_post_event" do
    test "relevant app", %{fake_marathon: fm} do
      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))

      assert_app_updates()
    end

    test "irrelevant app", %{fake_marathon: fm} do
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

      refute_updates()
    end
  end

  describe "status_update_event" do
    test "non-terminal state, relevant task", %{fake_marathon: fm} do
      # TODO: Should we be storing the tasks app some other way?
      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))
      # Clear the mailbox messages
      assert_app_updates()

      FakeMarathon.event(fm, "status_update_event", Poison.encode!(@test_status_update_event))

      assert_task_updates()
    end

    test "non-terminal state, irrelevant task", %{fake_marathon: fm} do
      # Don't store the app
      FakeMarathon.event(fm, "status_update_event", Poison.encode!(@test_status_update_event))

      refute_updates()
    end

    test "terminal state", %{fake_marathon: fm} do
      # TODO: Should we be storing the tasks app some other way?
      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))
      assert_app_updates()

      FakeMarathon.event(fm, "status_update_event", Poison.encode!(@test_status_update_event))
      assert_task_updates()

      event_data =
        @test_status_update_event
        |> Map.put("taskStatus", "TASK_KILLED")
        |> Poison.encode!()

      FakeMarathon.event(fm, "status_update_event", event_data)

      # Endpoint removed, same as if we just had app data
      assert_app_updates()
    end
  end
end
