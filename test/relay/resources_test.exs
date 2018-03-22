defmodule Relay.ResourcesTest do
  use ExUnit.Case, async: true

  alias Relay.{Publisher, Resources}
  alias Envoy.Api.V2.Core.{Address, DataSource, SocketAddress}

  setup do
    {:ok, pub} = start_supervised(Publisher)
    {:ok, res} = start_supervised({Resources, publisher: pub})
    %{pub: pub, res: res}
  end

  defp get_pub_state(pub, xds) do
    {:ok, resources} = GenServer.call(pub, {:_get_resources, xds})
    {resources.version_info, resources.resources}
  end

  defp listener_info(listener) do
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

        %Resources.CertInfo{
          domains: domains,
          key: unwrap_ds(cert.private_key),
          cert_chain: unwrap_ds(cert.certificate_chain)
        }
    end
  end

  defp unwrap_ds(%DataSource{specifier: {:inline_string, text}}), do: text

  test "does not push empty state at startup", %{pub: pub, res: res} do
    # The publisher has not received any listeners.
    assert get_pub_state(pub, :lds) == {"", []}
    # Send a no-op SNI cert update to trigger a push.
    :ok = Resources.update_sni_certs(res, "1", [])
    # The publisher has received HTTP and HTTPS listener with no certs.
    assert {"1", [http, https]} = get_pub_state(pub, :lds)
    assert listener_info(http) == {"http", 8080, [nil]}
    assert listener_info(https) == {"https", 8443, []}
  end

  test "pushes listeners with cert info in HTTP filter chains", %{pub: pub, res: res} do
    cert_info_1 = %Resources.CertInfo{
      domains: ["example.com"],
      key: "PEM key for example.com",
      cert_chain: "PEM certs for example.com"
    }

    cert_info_2 = %Resources.CertInfo{
      domains: ["example.net", "www.example.net"],
      key: "PEM key for example.net",
      cert_chain: "PEM certs for example.net"
    }

    # Add two certs.
    :ok = Resources.update_sni_certs(res, "1", [cert_info_1, cert_info_2])
    assert {"1", [http, https]} = get_pub_state(pub, :lds)
    assert listener_info(http) == {"http", 8080, [nil]}
    assert listener_info(https) == {"https", 8443, [cert_info_1, cert_info_2]}

    # Remove one cert.
    :ok = Resources.update_sni_certs(res, "2", [cert_info_1])
    assert {"2", [http, https]} = get_pub_state(pub, :lds)
    assert listener_info(http) == {"http", 8080, [nil]}
    assert listener_info(https) == {"https", 8443, [cert_info_1]}
  end
end
