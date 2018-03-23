defmodule LDSHelper do
  alias Relay.Resources

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

        %Resources.CertInfo{
          domains: domains,
          key: unwrap_ds(cert.private_key),
          cert_chain: unwrap_ds(cert.certificate_chain)
        }
    end
  end

  defp unwrap_ds(%DataSource{specifier: {:inline_string, text}}), do: text
end
