Code.require_file(Path.join([__DIR__, "resources_helper.exs"]))

defmodule Relay.Resources.LDSTest do
  use ExUnit.Case, async: true

  alias Relay.Resources.{CertInfo, LDS}

  import LDSHelper, only: [listener_info: 1]

  @cert_info_1 %CertInfo{
    domains: ["example.com"],
    key: "PEM key for example.com",
    cert_chain: "PEM certs for example.com"
  }

  @cert_info_2 %CertInfo{
    domains: ["example.net", "www.example.net"],
    key: "PEM key for example.net",
    cert_chain: "PEM certs for example.net"
  }

  test "basic HTTP listener and HTTPS listener with no certs" do
    assert [http, https] = LDS.listeners([])
    assert listener_info(http) == {"http", 8080, [nil]}
    assert listener_info(https) == {"https", 8443, []}
  end

  test "basic HTTP listener and HTTPS listener with one cert" do
    assert [http, https] = LDS.listeners([@cert_info_1])
    assert listener_info(http) == {"http", 8080, [nil]}
    assert listener_info(https) == {"https", 8443, [@cert_info_1]}
  end

  test "basic HTTP listener and HTTPS listener with two certs" do
    assert [http, https] = LDS.listeners([@cert_info_1, @cert_info_2])
    assert listener_info(http) == {"http", 8080, [nil]}
    assert listener_info(https) == {"https", 8443, [@cert_info_1, @cert_info_2]}
  end
end
