defmodule Relay.Resources.RDSTest do
  use ExUnit.Case, async: true

  alias Relay.Resources.{AppEndpoint, RDS}

  alias Envoy.Api.V2.RouteConfiguration
  alias Envoy.Api.V2.Route.{RedirectAction, Route, RouteAction, RouteMatch, VirtualHost}

  @simple_app_endpoint %AppEndpoint{
    name: "/mc2_0",
    domains: ["mc2.example.org"]
  }

  test "simple app routes" do
    assert [http_config, https_config] = RDS.routes([@simple_app_endpoint])

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

  test "multiple simple apps" do
    simple_app_endpoint2 = %{@simple_app_endpoint | name: "/mc3_0"}

    assert [http_config, https_config] = RDS.routes([@simple_app_endpoint, simple_app_endpoint2])

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

  test "simple virtual hosts" do
    assert [
             %RouteConfiguration{name: "http", virtual_hosts: [http_vhost]},
             %RouteConfiguration{name: "https", virtual_hosts: [https_vhost]}
           ] = RDS.routes([@simple_app_endpoint])

    assert %VirtualHost{
             name: "http_/mc2_0",
             domains: ["mc2.example.org"],
             routes: [
               %Route{
                 action: {:route, %RouteAction{cluster_specifier: {:cluster, "/mc2_0"}}},
                 match: %RouteMatch{path_specifier: {:prefix, "/"}}
               }
             ]
           } = http_vhost

    assert %VirtualHost{
             name: "https_/mc2_0",
             domains: ["mc2.example.org"],
             routes: [
               %Route{
                 action: {:route, %RouteAction{cluster_specifier: {:cluster, "/mc2_0"}}},
                 match: %RouteMatch{path_specifier: {:prefix, "/"}}
               }
             ]
           } = https_vhost

    assert Protobuf.Validator.valid?(http_vhost)
    assert Protobuf.Validator.valid?(https_vhost)
  end

  test "http to https redirect" do
    app_endpoint = %{@simple_app_endpoint | redirect_to_https: true}

    assert [
             %RouteConfiguration{name: "http", virtual_hosts: [http_vhost]},
             %RouteConfiguration{name: "https"}
           ] = RDS.routes([app_endpoint])

    assert %VirtualHost{
             name: "http_/mc2_0",
             domains: ["mc2.example.org"],
             routes: [
               %Route{
                 action: {:redirect, %RedirectAction{https_redirect: true}},
                 match: %RouteMatch{path_specifier: {:prefix, "/"}}
               }
             ]
           } = http_vhost

    assert Protobuf.Validator.valid?(http_vhost)
  end

  test "marathon-acme route" do
    app_endpoint = %{@simple_app_endpoint | marathon_acme_domains: ["mc2.example.org"]}

    # Change the defaults to ensure we're reading from config
    TestHelpers.put_env(:relay, :marathon_acme, app_id: "/ma", port_index: 1)

    assert [
             %RouteConfiguration{name: "http", virtual_hosts: [http_vhost]},
             %RouteConfiguration{name: "https"}
           ] = RDS.routes([app_endpoint])

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
           } = http_vhost

    assert Protobuf.Validator.valid?(http_vhost)
  end
end
