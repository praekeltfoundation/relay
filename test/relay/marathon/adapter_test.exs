defmodule Relay.Marathon.AdapterTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.{Adapter, App, Task}
  alias Relay.Resources.AppEndpoint

  alias Envoy.Api.V2.Cluster

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

  @test_task_2 %Task{
    address: "10.70.4.101",
    app_id: "/mc2",
    id: "mc2.be753491-1325-11e8-b5d6-4686525b33dc",
    ports: [15980],
    version: "2017-11-10T08:43:59.890Z"
  }

  test "simple app_endpoint no tasks" do
    assert [app_endpoint] = Adapter.app_endpoints_for_app(@test_app, [])

    assert app_endpoint == %AppEndpoint{
             name: "/mc2_0",
             domains: ["mc2.example.org"],
             addresses: [],
             # The following are all record defaults
             marathon_acme_domains: [],
             redirect_to_https: false,
             cluster_opts: []
           }
  end

  test "simple app_endpoint one task" do
    assert [app_endpoint] = Adapter.app_endpoints_for_app(@test_app, [@test_task])

    assert app_endpoint == %AppEndpoint{
             name: "/mc2_0",
             domains: ["mc2.example.org"],
             addresses: [{"10.70.4.100", 15979}]
           }
  end

  test "simple app_endpoint two tasks" do
    assert [app_endpoint] = Adapter.app_endpoints_for_app(@test_app, [@test_task, @test_task_2])

    assert app_endpoint == %AppEndpoint{
             name: "/mc2_0",
             domains: ["mc2.example.org"],
             addresses: [{"10.70.4.100", 15979}, {"10.70.4.101", 15980}]
           }
  end

  test "app_endpoint with cluster_opts" do
    connect_timeout = Duration.new(seconds: 10)
    lb_policy = Cluster.LbPolicy.value(:MAGLEV)

    assert [app_endpoint] =
             Adapter.app_endpoints_for_app(
               @test_app,
               [],
               cluster_opts: [connect_timeout: connect_timeout, lb_policy: lb_policy]
             )

    assert app_endpoint == %AppEndpoint{
             name: "/mc2_0",
             domains: ["mc2.example.org"],
             cluster_opts: [connect_timeout: connect_timeout, lb_policy: lb_policy]
           }
  end

  test "app_endpoint with https redirect" do
    app = %{
      @test_app
      | labels: @test_app.labels |> Map.put("HAPROXY_0_REDIRECT_TO_HTTPS", "true")
    }

    assert [app_endpoint] = Adapter.app_endpoints_for_app(app, [])

    assert app_endpoint == %AppEndpoint{
             name: "/mc2_0",
             domains: ["mc2.example.org"],
             redirect_to_https: true
           }
  end

  test "app_endpoint with marathon_acme_domains" do
    app = %{
      @test_app
      | labels: @test_app.labels |> Map.put("MARATHON_ACME_0_DOMAIN", "mc2.example.org")
    }

    assert [app_endpoint] = Adapter.app_endpoints_for_app(app, [])

    assert app_endpoint == %AppEndpoint{
             name: "/mc2_0",
             domains: ["mc2.example.org"],
             marathon_acme_domains: ["mc2.example.org"]
           }
  end
end
