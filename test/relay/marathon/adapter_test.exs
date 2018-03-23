defmodule Relay.Marathon.AdapterTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.{Adapter, App, Task}
  alias Relay.Resources

  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment}
  alias Envoy.Api.V2.Core.{Address, Locality, SocketAddress}
  alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}

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

  test "simple app_port_info" do
    assert [app_port_info] = Adapter.app_port_infos_for_app(@test_app)

    assert app_port_info == %Resources.AppPortInfo{
             name: "/mc2_0",
             domains: ["mc2.example.org"],
             # The following are all record defaults
             marathon_acme_domains: [],
             redirect_to_https: false,
             cluster_opts: []
           }
  end

  test "app_port_info with cluster_opts" do
    connect_timeout = Duration.new(seconds: 10)
    lb_policy = Cluster.LbPolicy.value(:MAGLEV)

    assert [app_port_info] =
             Adapter.app_port_infos_for_app(
               @test_app,
               cluster_opts: [connect_timeout: connect_timeout, lb_policy: lb_policy]
             )

    assert app_port_info == %Resources.AppPortInfo{
             name: "/mc2_0",
             domains: ["mc2.example.org"],
             cluster_opts: [connect_timeout: connect_timeout, lb_policy: lb_policy]
           }
  end

  test "app_port_info with https redirect" do
    app = %{
      @test_app
      | labels: @test_app.labels |> Map.put("HAPROXY_0_REDIRECT_TO_HTTPS", "true")
    }

    assert [app_port_info] = Adapter.app_port_infos_for_app(app)

    assert app_port_info == %Resources.AppPortInfo{
             name: "/mc2_0",
             domains: ["mc2.example.org"],
             redirect_to_https: true
           }
  end

  test "app_port_info with marathon_acme_domains" do
    app = %{
      @test_app
      | labels: @test_app.labels |> Map.put("MARATHON_ACME_0_DOMAIN", "mc2.example.org")
    }

    assert [app_port_info] = Adapter.app_port_infos_for_app(app)

    assert app_port_info == %Resources.AppPortInfo{
             name: "/mc2_0",
             domains: ["mc2.example.org"],
             marathon_acme_domains: ["mc2.example.org"]
           }
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
end
