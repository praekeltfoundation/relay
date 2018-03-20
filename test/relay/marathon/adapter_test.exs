defmodule Relay.Marathon.AdapterTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.{Adapter, App, Task}

  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment, RouteConfiguration}
  alias Envoy.Api.V2.Core.{Address, ConfigSource, Locality, SocketAddress}
  alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}
  alias Envoy.Api.V2.Route.{RedirectAction, Route, RouteAction, RouteMatch, VirtualHost}

  alias Google.Protobuf.Duration

  @test_app %App{
    id: "/mc2",
    labels: %{
      "HAPROXY_0_REDIRECT_TO_HTTPS" => "false",
      "HAPROXY_0_VHOST" => "mc2.example.org",
      "HAPROXY_GROUP" => "external",
      "MARATHON_ACME_0_DOMAIN" => ""
    },
    networking_mode: :"container/bridge",
    ports_list: [80],
    port_indices_in_group: [0],
    version: "2017-11-08T15:06:31.066Z"
  }

  @test_task %Task{
    address: "10.70.4.100",
    app_id: "/mc2",
    id: "mc2.be753491-1325-11e8-b5d6-4686525b33db",
    ports: [15979],
    version: "2017-11-09T08:43:59.890Z"
  }

  describe "app_clusters/3" do
    test "simple cluster" do
      eds_type = Cluster.DiscoveryType.value(:EDS)
      assert [cluster] = Adapter.app_clusters(@test_app)

      assert %Cluster{
               name: "/mc2_0",
               type: ^eds_type,
               eds_cluster_config: %Cluster.EdsClusterConfig{
                 eds_config: %ConfigSource{},
                 service_name: "/mc2_0"
               },
               connect_timeout: %Duration{seconds: 5}
             } = cluster

      assert Protobuf.Validator.valid?(cluster)
    end

    test "cluster with options" do
      eds_type = Cluster.DiscoveryType.value(:EDS)
      connect_timeout = Duration.new(seconds: 10)
      lb_policy = Cluster.LbPolicy.value(:MAGLEV)

      assert [cluster] =
               Adapter.app_clusters(
                 @test_app,
                 connect_timeout: connect_timeout,
                 lb_policy: lb_policy
               )

      assert %Cluster{
               name: "/mc2_0",
               type: ^eds_type,
               eds_cluster_config: %Cluster.EdsClusterConfig{
                 eds_config: %ConfigSource{},
                 service_name: "/mc2_0"
               },
               connect_timeout: ^connect_timeout,
               lb_policy: ^lb_policy
             } = cluster

      assert Protobuf.Validator.valid?(cluster)
    end

    test "cluster with long name" do
      app = %{@test_app | id: "/organisation/my_long_group_name/subgroup3456/application2934"}

      assert [%Cluster{name: "[...]ation/my_long_group_name/subgroup3456/application2934_0"}] =
               Adapter.app_clusters(app)
    end
  end

  describe "app_cluster_load_assignments/3" do
    test "simple cluster load assignment" do
      assert [cla] = Adapter.app_cluster_load_assignments(@test_app, [@test_task])

      assert %ClusterLoadAssignment{
               cluster_name: "/mc2_0",
               endpoints: [
                 %LocalityLbEndpoints{
                   locality: %Locality{region: "default"},
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
             } = cla

      assert Protobuf.Validator.valid?(cla)
    end

    test "cluster load assignment with options" do
      alias Google.Protobuf.{UInt32Value, UInt64Value}

      assert [cla] =
               Adapter.app_cluster_load_assignments(
                 @test_app,
                 [@test_task],
                 policy: ClusterLoadAssignment.Policy.new(drop_overload: 5.0),
                 locality_lb_endpoints_opts: [
                   load_balancing_weight: UInt64Value.new(value: 42),
                   lb_endpoint_opts: [
                     load_balancing_weight: UInt32Value.new(value: 13)
                   ]
                 ]
               )

      assert %ClusterLoadAssignment{
               policy: %ClusterLoadAssignment.Policy{drop_overload: 5.0},
               endpoints: [
                 %LocalityLbEndpoints{
                   load_balancing_weight: %UInt64Value{value: 42},
                   lb_endpoints: [
                     %LbEndpoint{load_balancing_weight: %UInt32Value{value: 13}}
                   ]
                 }
               ]
             } = cla

      assert Protobuf.Validator.valid?(cla)
    end
  end

  describe "app_virtual_hosts/3" do
    test "http virtual host" do
      app = @test_app

      assert [virtual_host] = Adapter.app_virtual_hosts(:http, app)

      assert %VirtualHost{
               name: "http_/mc2_0",
               domains: ["mc2.example.org"],
               routes: [
                 %Route{
                   action: {:route, %RouteAction{cluster_specifier: {:cluster, "/mc2_0"}}},
                   match: %RouteMatch{path_specifier: {:prefix, "/"}}
                 }
               ]
             } = virtual_host

      assert Protobuf.Validator.valid?(virtual_host)
    end

    test "https virtual host" do
      assert [virtual_host] = Adapter.app_virtual_hosts(:https, @test_app)

      assert %VirtualHost{
               name: "https_/mc2_0",
               domains: ["mc2.example.org"],
               routes: [
                 %Route{
                   action: {:route, %RouteAction{cluster_specifier: {:cluster, "/mc2_0"}}},
                   match: %RouteMatch{path_specifier: {:prefix, "/"}}
                 }
               ]
             } = virtual_host

      assert Protobuf.Validator.valid?(virtual_host)
    end

    test "http virtual host with options" do
      alias Envoy.Api.V2.Core.{HeaderValue, HeaderValueOption, RuntimeUInt32}
      alias Envoy.Api.V2.Route.Decorator
      alias Google.Protobuf.UInt32Value

      assert [virtual_host] =
               Adapter.app_virtual_hosts(
                 :http,
                 @test_app,
                 response_headers_to_add: [
                   HeaderValueOption.new(
                     header:
                       HeaderValue.new(
                         key: "Strict-Transport-Security",
                         value: "max-age=31536000"
                       )
                   )
                 ],
                 route_opts: [
                   decorator: Decorator.new(operation: "mytrace"),
                   action_opts: [
                     retry_policy:
                       RouteAction.RetryPolicy.new(num_retries: UInt32Value.new(value: 3))
                   ],
                   match_opts: [
                     runtime:
                       RuntimeUInt32.new(
                         runtime_key: "routing.traffic_shift.helloworld",
                         default_value: 50
                       )
                   ]
                 ]
               )

      assert %VirtualHost{
               response_headers_to_add: [
                 %HeaderValueOption{
                   header: %HeaderValue{
                     key: "Strict-Transport-Security",
                     value: "max-age=31536000"
                   }
                 }
               ],
               routes: [
                 %Route{
                   decorator: %Decorator{operation: "mytrace"},
                   action:
                     {:route,
                      %RouteAction{
                        retry_policy: %RouteAction.RetryPolicy{
                          num_retries: %UInt32Value{value: 3}
                        }
                      }},
                   match: %RouteMatch{
                     runtime: %RuntimeUInt32{
                       runtime_key: "routing.traffic_shift.helloworld",
                       default_value: 50
                     }
                   }
                 }
               ]
             } = virtual_host

      assert Protobuf.Validator.valid?(virtual_host)
    end

    test "http to https redirect" do
      app = %{
        @test_app
        | labels: @test_app.labels |> Map.put("HAPROXY_0_REDIRECT_TO_HTTPS", "true")
      }

      assert [virtual_host] = Adapter.app_virtual_hosts(:http, app)

      assert %VirtualHost{
               name: "http_/mc2_0",
               domains: ["mc2.example.org"],
               routes: [
                 %Route{
                   action: {:redirect, %RedirectAction{https_redirect: true}},
                   match: %RouteMatch{path_specifier: {:prefix, "/"}}
                 }
               ]
             } = virtual_host

      assert Protobuf.Validator.valid?(virtual_host)
    end

    test "marathon-acme route" do
      app = %{
        @test_app
        | labels: @test_app.labels |> Map.put("MARATHON_ACME_0_DOMAIN", "mc2.example.org")
      }
      # Change the defaults to ensure we're reading from config
      TestHelpers.put_env(:relay, :marathon_acme, [app_id: "/ma", port_index: 1])

      assert [virtual_host] = Adapter.app_virtual_hosts(:http, app)

      assert %VirtualHost{
               name: "http_/mc2_0",
               domains: ["mc2.example.org"],
               routes: [
                 %Route{
                   action: {:route, %RouteAction{cluster_specifier: {:cluster, "/ma_1"}}},
                   match: %RouteMatch{path_specifier: {:prefix, "/.well-known/acme-challenge/"}}
                 },
                 %Route{
                   action: {:route, %RouteAction{cluster_specifier: {:cluster, "/mc2_0"}}},
                   match: %RouteMatch{path_specifier: {:prefix, "/"}}
                 }
               ]
             } = virtual_host

      assert Protobuf.Validator.valid?(virtual_host)
    end

    test "other listeners rejected" do
      assert_raise ArgumentError, "Unknown listener 'ftp'. Known listeners: http, https", fn ->
        Adapter.app_virtual_hosts(:ftp, @test_app)
      end
    end
  end

  describe "apps_route_configurations/2" do
    test "simple app" do
      assert [http_config, https_config] = Adapter.apps_route_configurations([@test_app])

      assert %RouteConfiguration{
               name: "http",
               virtual_hosts: [%VirtualHost{name: "http_/mc2_0"}]
             } = http_config

      assert %RouteConfiguration{
               name: "https",
               virtual_hosts: [%VirtualHost{name: "https_/mc2_0"}]
             } = https_config

      assert Protobuf.Validator.valid?(http_config)
      assert Protobuf.Validator.valid?(https_config)
    end

    test "multiple apps" do
      test_app2 = %{@test_app | id: "/mc3"}

      assert [http_config, https_config] =
               Adapter.apps_route_configurations([@test_app, test_app2])

      assert %RouteConfiguration{
               name: "http",
               virtual_hosts: [
                 %VirtualHost{name: "http_/mc2_0"},
                 %VirtualHost{name: "http_/mc3_0"}
               ]
             } = http_config

      assert %RouteConfiguration{
               name: "https",
               virtual_hosts: [
                 %VirtualHost{name: "https_/mc2_0"},
                 %VirtualHost{name: "https_/mc3_0"}
               ]
             } = https_config

      assert Protobuf.Validator.valid?(http_config)
      assert Protobuf.Validator.valid?(https_config)
    end

    test "custom options" do
      alias Envoy.Api.V2.Core.{HeaderValue, HeaderValueOption}
      alias Google.Protobuf.BoolValue

      assert [http_config, https_config] =
               Adapter.apps_route_configurations(
                 [@test_app],
                 http_opts: [
                   name: "router",
                   validate_clusters: BoolValue.new(value: true),
                   virtual_host_opts: [
                     response_headers_to_add: [
                       HeaderValueOption.new(
                         header:
                           HeaderValue.new(
                             key: "Strict-Transport-Security",
                             value: "max-age=31536000"
                           )
                       )
                     ]
                   ]
                 ],
                 https_opts: [name: "tls-router"]
               )

      assert %RouteConfiguration{
               name: "router",
               virtual_hosts: [
                 %VirtualHost{
                   response_headers_to_add: [
                     %HeaderValueOption{
                       header: %HeaderValue{
                         key: "Strict-Transport-Security",
                         value: "max-age=31536000"
                       }
                     }
                   ]
                 }
               ],
               validate_clusters: %BoolValue{value: true}
             } = http_config

      assert %RouteConfiguration{name: "tls-router"} = https_config

      assert Protobuf.Validator.valid?(http_config)
      assert Protobuf.Validator.valid?(https_config)
    end
  end
end
