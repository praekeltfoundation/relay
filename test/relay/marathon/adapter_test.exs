defmodule Relay.Marathon.AdapterTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.{Adapter, App, Task}

  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment}
  alias Envoy.Api.V2.Core.{Address, ApiConfigSource, ConfigSource, Locality, SocketAddress}
  alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}
  alias Envoy.Api.V2.Route.{RedirectAction, Route, RouteAction, RouteMatch, VirtualHost}

  alias Google.Protobuf.Duration

  @test_app %App{
    id: "/mc2",
    labels: %{
      "HAPROXY_0_REDIRECT_TO_HTTPS" => "true",
      "HAPROXY_0_VHOST" => "mc2.example.org",
      "HAPROXY_GROUP" => "external",
      "MARATHON_ACME_0_DOMAIN" => "mc2.example.org"
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

  @test_config_source ConfigSource.new(
                        config_source_specifier:
                          {:api_config_source,
                           ApiConfigSource.new(
                             api_type: ApiConfigSource.ApiType.value(:GRPC),
                             cluster_names: ["xds_cluster"]
                           )}
                      )

  describe "truncate_name/2" do
    test "long names truncated from beginning" do
      assert Adapter.truncate_name("helloworldmynameis", 10) == "[...]ameis"
    end

    test "short names unchanged" do
      assert Adapter.truncate_name("hello", 10) == "hello"
    end

    test "max_size must be larger than the prefix length" do
      assert_raise ArgumentError, "`max_size` must be larger than the prefix length", fn ->
        Adapter.truncate_name("hello", 3)
      end
    end
  end

  describe "app_clusters/3" do
    test "simple cluster" do
      eds_type = Cluster.DiscoveryType.value(:EDS)
      assert [cluster] = Adapter.app_clusters(@test_app, @test_config_source)

      assert %Cluster{
               name: "/mc2_0",
               type: ^eds_type,
               eds_cluster_config: %Cluster.EdsClusterConfig{
                 eds_config: @test_config_source,
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
          @test_config_source,
          connect_timeout: connect_timeout,
          lb_policy: lb_policy
        )

      assert %Cluster{
               name: "/mc2_0",
               type: ^eds_type,
               eds_cluster_config: %Cluster.EdsClusterConfig{
                 eds_config: @test_config_source,
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
               Adapter.app_clusters(app, @test_config_source)
    end

    test "custom max_obj_name_length" do
      app = %{@test_app | id: "/myslightlylongname"}
      assert [cluster] = Adapter.app_clusters(app, @test_config_source, max_obj_name_length: 10)

      assert %Cluster{name: "[...]ame_0"} = cluster
      assert Protobuf.Validator.valid?(cluster)
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

  describe "app_port_virtual_host/3" do
    test "http virtual host" do
      app = %{
        @test_app
        | labels: @test_app.labels |> Map.put("HAPROXY_0_REDIRECT_TO_HTTPS", "false")
      }

      virtual_host = Adapter.app_port_virtual_host(:http, app, 0)

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
      app = %{
        @test_app
        | labels: @test_app.labels |> Map.put("HAPROXY_0_REDIRECT_TO_HTTPS", "false")
      }

      virtual_host = Adapter.app_port_virtual_host(:https, app, 0)

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

      app = %{
        @test_app
        | labels: @test_app.labels |> Map.put("HAPROXY_0_REDIRECT_TO_HTTPS", "false")
      }

      virtual_host =
        Adapter.app_port_virtual_host(
          :http,
          app,
          0,
          response_headers_to_add: [
            HeaderValueOption.new(
              header: HeaderValue.new(key: "Strict-Transport-Security", value: "max-age=31536000")
            )
          ],
          route_opts: [
            decorator: Decorator.new(operation: "mytrace"),
            action_opts: [
              retry_policy: RouteAction.RetryPolicy.new(num_retries: UInt32Value.new(value: 3))
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
      virtual_host = Adapter.app_port_virtual_host(:http, @test_app, 0)

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

    test "other listeners rejected" do
      assert_raise ArgumentError, "only :http and :https listeners supported", fn ->
        Adapter.app_port_virtual_host(:ftp, @test_app, 0)
      end
    end
  end
end
