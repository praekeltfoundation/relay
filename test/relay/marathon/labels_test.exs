defmodule Relay.Marathon.LabelsTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.Labels

  test "get app label value" do
    labels = %{"HAPROXY_GROUP" => "external"}

    assert Labels.app_label(labels, "GROUP") == "external"
  end

  test "get app label value with custom options" do
    labels = %{"traefik.group" => "external"}

    assert Labels.app_label(labels, "group", prefix: "traefik", sep: ".") == "external"
  end

  test "get app label default value" do
    labels = %{"HAPROXY_GROUP" => "external"}

    assert Labels.app_label(labels, "GROUP", default: "internal") == "external"
    assert Labels.app_label(labels, "ENABLED", default: "true") == "true"
  end

  test "get port label value" do
    labels = %{
      "HAPROXY_GROUP" => "internal",
      "HAPROXY_0_GROUP" => "external"
    }

    assert Labels.port_label(labels, "GROUP", 0) == "external"
  end

  test "get port label value with custom options" do
    labels = %{"traefik.1.group" => "front-end"}

    assert Labels.port_label(labels, "group", 1, prefix: "traefik", sep: ".") == "front-end"
  end

  test "get port label default value" do
    labels = %{"HAPROXY_1_GROUP" => "external"}

    assert Labels.port_label(labels, "GROUP", 1, default: "internal") == "external"
    assert Labels.port_label(labels, "ENABLED", 2, default: "true") == "true"
  end

  test "port in group" do
    port_label = %{"HAPROXY_0_GROUP" => "external"}
    assert Labels.port_in_group?(port_label, 0, "external")

    app_label = %{"HAPROXY_GROUP" => "external"}
    assert Labels.port_in_group?(app_label, 0, "external")

    mismatch_label = %{"HAPROXY_0_GROUP" => "internal"}
    assert not Labels.port_in_group?(mismatch_label, 0, "external")

    no_label = %{"HAPROXY_1_GROUP" => "external"}
    assert not Labels.port_in_group?(no_label, 0, "external")
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
