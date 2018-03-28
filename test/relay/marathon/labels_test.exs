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

  test "get marathon-lb redirect to HTTPS" do
    true_label = %{"HAPROXY_0_REDIRECT_TO_HTTPS" => "true"}
    assert Labels.marathon_lb_redirect_to_https?(true_label, 0)

    false_label = %{"HAPROXY_0_REDIRECT_TO_HTTPS" => "false"}
    assert not Labels.marathon_lb_redirect_to_https?(false_label, 0)

    no_label = %{"HAPROXY_1_VHOST" => "example.com"}
    assert not Labels.marathon_lb_redirect_to_https?(no_label, 0)
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
