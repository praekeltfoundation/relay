Code.require_file(Path.join([__DIR__, "..", "marathon_client", "marathon_client_helper.exs"]))

defmodule Relay.MarathonTest do
  use ExUnit.Case, async: false

  alias Relay.{Publisher, Marathon, Resources}
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

    assert_receive {:cds, _version,
                    [
                      %Cluster{name: "/jamie-event-test_0"},
                      %Cluster{name: "/mc2_0"}
                    ]},
                   100
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
                           },
                           %VirtualHost{
                             domains: ["mc2.example.org"],
                             routes: [
                               %Route{
                                 action:
                                   {:route,
                                    %RouteAction{
                                      cluster_specifier: {:cluster, "/mc2_0"}
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
                           },
                           %VirtualHost{
                             domains: ["mc2.example.org"],
                             routes: [
                               %Route{
                                 action:
                                   {:route,
                                    %RouteAction{
                                      cluster_specifier: {:cluster, "/mc2_0"}
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
    alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}
    alias Envoy.Api.V2.Core.{Address, SocketAddress}

    assert_receive {:eds, _version,
                    [
                      %ClusterLoadAssignment{
                        cluster_name: "/jamie-event-test_0",
                        endpoints: [%LocalityLbEndpoints{lb_endpoints: []}]
                      },
                      %ClusterLoadAssignment{
                        cluster_name: "/mc2_0",
                        endpoints: [
                          %LocalityLbEndpoints{
                            lb_endpoints: [
                              %LbEndpoint{
                                endpoint: %Endpoint{
                                  address: %Address{
                                    address:
                                      {:socket_address,
                                       %SocketAddress{
                                         address: "10.70.4.100",
                                         port_specifier: {:port_value, 15979}
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
                      },
                      %ClusterLoadAssignment{
                        cluster_name: "/mc2_0",
                        endpoints: [
                          %LocalityLbEndpoints{
                            lb_endpoints: [
                              %LbEndpoint{
                                endpoint: %Endpoint{
                                  address: %Address{
                                    address:
                                      {:socket_address,
                                       %SocketAddress{
                                         address: "10.70.4.100",
                                         port_specifier: {:port_value, 15979}
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

  defp assert_receive_synced_updates do
    alias Envoy.Api.V2.Cluster
    assert_receive {:cds, _version, [%Cluster{name: "/mc2_0"}]}, 100

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
                             domains: ["mc2.example.org"],
                             routes: [
                               %Route{
                                 action:
                                   {:route,
                                    %RouteAction{
                                      cluster_specifier: {:cluster, "/mc2_0"}
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
                             domains: ["mc2.example.org"],
                             routes: [
                               %Route{
                                 action:
                                   {:route,
                                    %RouteAction{
                                      cluster_specifier: {:cluster, "/mc2_0"}
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

    alias Envoy.Api.V2.ClusterLoadAssignment
    alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}
    alias Envoy.Api.V2.Core.{Address, SocketAddress}

    assert_receive {:eds, _version,
                    [
                      %ClusterLoadAssignment{
                        cluster_name: "/mc2_0",
                        endpoints: [
                          %LocalityLbEndpoints{
                            lb_endpoints: [
                              %LbEndpoint{
                                endpoint: %Endpoint{
                                  address: %Address{
                                    address:
                                      {:socket_address,
                                       %SocketAddress{
                                         address: "10.70.4.100",
                                         port_specifier: {:port_value, 15979}
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
      assert_receive_synced_updates()

      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))

      assert_app_updates()
    end

    test "irrelevant app", %{fake_marathon: fm} do
      assert_receive_synced_updates()

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

    test "app becomes irrelevant", %{fake_marathon: fm} do
      assert_receive_synced_updates()

      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))
      assert_app_updates()

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

      assert_receive_synced_updates()
    end
  end

  describe "app_terminated_event" do
    test "app removed", %{fake_marathon: fm} do
      assert_receive_synced_updates()

      # TODO: Should we be storing the tasks app some other way?
      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))
      # Clear the mailbox messages
      assert_app_updates()

      FakeMarathon.event(fm, "app_terminated_event", Poison.encode!(@test_app_terminated_event))

      assert_receive_synced_updates()
    end
  end

  describe "status_update_event" do
    test "non-terminal state, relevant task", %{fake_marathon: fm} do
      assert_receive_synced_updates()

      # TODO: Should we be storing the tasks app some other way?
      FakeMarathon.event(fm, "api_post_event", Poison.encode!(@test_api_post_event))
      # Clear the mailbox messages
      assert_app_updates()

      FakeMarathon.event(fm, "status_update_event", Poison.encode!(@test_status_update_event))

      assert_task_updates()
    end

    test "non-terminal state, irrelevant task", %{fake_marathon: fm} do
      assert_receive_synced_updates()

      # Don't store the app
      FakeMarathon.event(fm, "status_update_event", Poison.encode!(@test_status_update_event))

      refute_updates()
    end

    test "terminal state", %{fake_marathon: fm} do
      assert_receive_synced_updates()

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

  test "irrelevant event", %{fake_marathon: fm} do
    assert_receive_synced_updates()

    event = %{
      "remoteAddress" => "10.0.91.9",
      "eventType" => "event_stream_attached",
      "timestamp" => "2018-04-11T11:45:47.417Z"
    }

    FakeMarathon.event(fm, "event_stream_attached", Poison.encode!(event))

    refute_updates()
  end
end
