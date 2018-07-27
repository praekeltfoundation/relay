defmodule Relay.Resources.RDSTest do
  use ExUnit.Case, async: true

  alias Relay.Resources.{AppEndpoint, RDS}

  alias Envoy.Api.V2.{Route, RouteConfiguration}
  alias Route.{VirtualHost, RedirectAction, RouteAction, RouteMatch}

  @simple_app_endpoint %AppEndpoint{
    name: "/mc2_0",
    domains: ["mc2.example.org"]
  }

  test "simple app routes" do
    assert [http_config, https_config] = RDS.route_configurations([@simple_app_endpoint])

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

  test "routes with vhost options" do
    alias Envoy.Api.V2.Core.{HeaderValue, HeaderValueOption}
    alias Google.Protobuf.BoolValue

    response_headers_to_add =
      HeaderValueOption.new(
        header: HeaderValue.new(key: "Strict-Transport-Security", value: "max-age=31536000"),
        append: BoolValue.new(value: false)
      )

    app_endpoint = %AppEndpoint{
      @simple_app_endpoint
      | vhost_opts: [response_headers_to_add: response_headers_to_add]
    }

    assert [http_config, https_config] = RDS.route_configurations([app_endpoint])

    assert %RouteConfiguration{
             virtual_hosts: [%VirtualHost{response_headers_to_add: ^response_headers_to_add}]
           } = http_config

    assert %RouteConfiguration{
             virtual_hosts: [%VirtualHost{response_headers_to_add: ^response_headers_to_add}]
           } = https_config

    assert Protobuf.Validator.valid?(http_config)
    assert Protobuf.Validator.valid?(https_config)
  end

  test "route with route options" do
    alias Google.Protobuf.BoolValue

    route_decorator = Route.Decorator.new(operation: "ingress")
    route_action_use_websocket = BoolValue.new(value: true)
    route_match_headers = [Route.HeaderMatcher.new(name: "method", value: "POST")]

    app_endpoint = %AppEndpoint{
      @simple_app_endpoint
      | route_opts: [decorator: route_decorator],
        route_action_opts: [use_websocket: route_action_use_websocket],
        route_match_opts: [headers: route_match_headers]
    }

    assert [http_config, https_config] = RDS.route_configurations([app_endpoint])

    assert %RouteConfiguration{
             virtual_hosts: [
               %VirtualHost{
                 routes: [
                   %Route.Route{
                     decorator: ^route_decorator,
                     action: {:route, %RouteAction{use_websocket: ^route_action_use_websocket}},
                     match: %RouteMatch{headers: ^route_match_headers}
                   }
                 ]
               }
             ]
           } = http_config

    assert %RouteConfiguration{
             virtual_hosts: [
               %VirtualHost{
                 routes: [
                   %Route.Route{
                     decorator: ^route_decorator,
                     action: {:route, %RouteAction{use_websocket: ^route_action_use_websocket}},
                     match: %RouteMatch{headers: ^route_match_headers}
                   }
                 ]
               }
             ]
           } = https_config

    assert Protobuf.Validator.valid?(http_config)
    assert Protobuf.Validator.valid?(https_config)
  end

  test "multiple simple apps" do
    simple_app_endpoint2 = %AppEndpoint{name: "/mc3_0", domains: ["mc3.example.org"]}

    assert [http_config, https_config] =
             RDS.route_configurations([@simple_app_endpoint, simple_app_endpoint2])

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
           ] = RDS.route_configurations([@simple_app_endpoint])

    assert %VirtualHost{
             name: "http_/mc2_0",
             domains: ["mc2.example.org"],
             routes: [
               %Route.Route{
                 action: {:route, %RouteAction{cluster_specifier: {:cluster, "/mc2_0"}}},
                 match: %RouteMatch{path_specifier: {:prefix, "/"}}
               }
             ]
           } = http_vhost

    assert %VirtualHost{
             name: "https_/mc2_0",
             domains: ["mc2.example.org"],
             routes: [
               %Route.Route{
                 action: {:route, %RouteAction{cluster_specifier: {:cluster, "/mc2_0"}}},
                 match: %RouteMatch{path_specifier: {:prefix, "/"}}
               }
             ]
           } = https_vhost

    assert Protobuf.Validator.valid?(http_vhost)
    assert Protobuf.Validator.valid?(https_vhost)
  end

  test "duplicate domains" do
    # app1 has only duplicate domains, so it will be filtered out completely.
    app1 = %AppEndpoint{name: "/app1", domains: ["foo.xyz"]}
    # app2 has a mix of dups and non-dups, so it will lose the dups.
    app2 = %AppEndpoint{name: "/app2", domains: ["foo.xyz", "bar.xyz"]}
    # app2 has no duplicate domains, so it won't be touched.
    app3 = %AppEndpoint{name: "/app3", domains: ["baz.xyz", "quux.xyz"]}

    assert [
             %RouteConfiguration{name: "http", virtual_hosts: [http2, http3]},
             %RouteConfiguration{name: "https", virtual_hosts: [https2, https3]}
           ] = RDS.route_configurations([app1, app2, app3])

    assert %VirtualHost{name: "http_/app2", domains: ["bar.xyz"]} = http2
    assert %VirtualHost{name: "https_/app2", domains: ["bar.xyz"]} = https2

    assert %VirtualHost{name: "http_/app3", domains: ["baz.xyz", "quux.xyz"]} = http3
    assert %VirtualHost{name: "https_/app3", domains: ["baz.xyz", "quux.xyz"]} = https3
  end

  test "http to https redirect" do
    app_endpoint = %{@simple_app_endpoint | redirect_to_https: true}

    assert [
             %RouteConfiguration{name: "http", virtual_hosts: [http_vhost]},
             %RouteConfiguration{name: "https"}
           ] = RDS.route_configurations([app_endpoint])

    assert %VirtualHost{
             name: "http_/mc2_0",
             domains: ["mc2.example.org"],
             routes: [
               %Route.Route{
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
           ] = RDS.route_configurations([app_endpoint])

    assert %VirtualHost{
             name: "http_/mc2_0",
             domains: ["mc2.example.org"],
             routes: [
               %Route.Route{
                 action: {:route, %RouteAction{cluster_specifier: {:cluster, "/ma_1"}}},
                 match: %RouteMatch{path_specifier: {:prefix, "/.well-known/acme-challenge/"}}
               },
               %Route.Route{
                 action: {:route, %RouteAction{cluster_specifier: {:cluster, "/mc2_0"}}},
                 match: %RouteMatch{path_specifier: {:prefix, "/"}}
               }
             ]
           } = http_vhost

    assert Protobuf.Validator.valid?(http_vhost)
  end
end
