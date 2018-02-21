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

  test "get marathon-lb vhost" do
    labels = %{"HAPROXY_0_VHOST" => "example.com, www.example.com"}
    assert Labels.marathon_lb_vhost(labels, 0) == ["example.com", "www.example.com"]

    no_label = %{"HAPROXY_1_VHOST" => "example.com"}
    assert Labels.marathon_lb_vhost(no_label, 0) == []
  end

  test "get marathon-acme domain" do
    labels = %{"MARATHON_ACME_0_DOMAIN" => "example.com, www.example.com"}
    assert Labels.marathon_acme_domain(labels, 0) == ["example.com", "www.example.com"]

    no_label = %{"MARATHON_ACME_1_DOMAIN" => "example.com"}
    assert Labels.marathon_acme_domain(no_label, 0) == []
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
