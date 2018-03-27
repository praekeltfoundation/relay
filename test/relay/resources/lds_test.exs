defmodule Relay.Resources.LDSTest do
  use ExUnit.Case, async: true

  alias Relay.Resources.{CertInfo, LDS}

  alias Envoy.Api.V2.Core.{Address, DataSource, SocketAddress}

  def listener_info(listener) do
    %Address{address: {:socket_address, socket_address}} = listener.address
    %SocketAddress{port_specifier: {:port_value, port}} = socket_address
    cert_infos = Enum.map(listener.filter_chains, &extract_cert_info/1)
    {listener.name, port, cert_infos}
  end

  defp extract_cert_info(filter_chain) do
    case {filter_chain.filter_chain_match, filter_chain.tls_context} do
      {%{sni_domains: []}, nil} ->
        nil

      {%{sni_domains: domains}, tls_context} ->
        [cert] = tls_context.common_tls_context.tls_certificates

        %CertInfo{
          domains: domains,
          key: unwrap_ds(cert.private_key),
          cert_chain: unwrap_ds(cert.certificate_chain)
        }
    end
  end

  defp unwrap_ds(%DataSource{specifier: {:inline_string, text}}), do: text

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
