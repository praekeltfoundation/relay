defmodule Relay.Marathon.LabelsTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.Labels

  test "get marathon-lb group" do
    port_label = %{"HAPROXY_0_GROUP" => "external"}
    assert Labels.marathon_lb_group(port_label, 0) == "external"

    app_label = %{"HAPROXY_GROUP" => "internal"}
    assert Labels.marathon_lb_group(app_label, 0) == "internal"

    port_and_app_label = %{
      "HAPROXY_GROUP" => "internal",
      "HAPROXY_0_GROUP" => "external"
    }
    assert Labels.marathon_lb_group(port_and_app_label, 0) == "external"

    no_label = %{"HAPROXY_1_GROUP" => "external"}
    assert Labels.marathon_lb_group(no_label, 0) == nil
  end

  test "get marathon-lb group with custom options" do
    port_label = %{"traefik.0.cluster" => "external"}
    assert Labels.marathon_lb_group(
      port_label, 0, prefix: "traefik", label: "cluster", sep: ".") == "external"

    app_label = %{"MLB-GROUP" => "internal"}
    assert Labels.marathon_lb_group(app_label, 0, prefix: "MLB", sep: "-") == "internal"
  end

  test "parse domains label" do
    assert Labels.parse_domains_label("example.com") == ["example.com"]
    assert Labels.parse_domains_label("foo.com example.com") == ["foo.com", "example.com"]
    assert Labels.parse_domains_label("foo.com,example.com") == ["foo.com", "example.com"]
    assert Labels.parse_domains_label(" , foo.com,  example.com, ,") == ["foo.com", "example.com"]
    assert Labels.parse_domains_label("") == []
    assert Labels.parse_domains_label("   ,") == []
  end
end
