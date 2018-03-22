defmodule Relay.Resources.LDS do
  alias Envoy.Api.V2.Listener
  alias Relay.{EnvoyUtil, Resources.CertInfo}

  @spec listeners([CertInfo.t()]) :: [Listener.t()]
  def listeners(cert_infos) do
    https_filter_chains = Enum.map(cert_infos, &https_filter_chain/1)

    [
      EnvoyUtil.listener(:http, [filter_chain(:http)]),
      EnvoyUtil.listener(:https, https_filter_chains)
    ]
  end

  defp https_filter_chain(cert_info) do
    alias Envoy.Api.V2.Auth

    tls_context =
      Auth.DownstreamTlsContext.new(
        common_tls_context:
          Auth.CommonTlsContext.new(
            alpn_protocols: ["h2,http/1.1"],
            tls_certificates: [
              Auth.TlsCertificate.new(
                certificate_chain: inline_string(cert_info.cert_chain),
                private_key: inline_string(cert_info.key)
              )
            ]
          )
      )

    filter_chain(:https, {tls_context, cert_info.domains})
  end

  defp inline_string(text),
    do: Envoy.Api.V2.Core.DataSource.new(specifier: {:inline_string, text})

  defp filter_chain(listener, {tls_context, sni_domains} \\ {nil, []}) do
    alias Envoy.Api.V2.Listener.{FilterChain, FilterChainMatch}

    FilterChain.new(
      filter_chain_match: FilterChainMatch.new(sni_domains: sni_domains),
      filters: [EnvoyUtil.http_connection_manager_filter(listener)],
      tls_context: tls_context
    )
  end
end
