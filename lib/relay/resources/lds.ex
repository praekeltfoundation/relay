defmodule Relay.Resources.LDS do
  alias Envoy.Api.V2.Listener
  alias Relay.{EnvoyUtil, Resources.CertInfo}

  @spec listeners([CertInfo.t()]) :: Listener.t()
  def listeners(cert_infos) do
    https_filter_chains = Enum.map(cert_infos, &https_filter_chain/1)

    [
      listener("http", EnvoyUtil.listener_address(:http), [filter_chain("http")]),
      listener("https", EnvoyUtil.listener_address(:https), https_filter_chains)
    ]
  end

  defp listener(name, address, filter_chains) do
    alias Envoy.Api.V2.Listener
    Listener.new(name: name, address: address, filter_chains: filter_chains)
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

    filter_chain("https", {tls_context, cert_info.domains})
  end

  defp inline_string(text),
    do: Envoy.Api.V2.Core.DataSource.new(specifier: {:inline_string, text})

  defp filter_chain(name, {tls_context, sni_domains} \\ {nil, []}) do
    alias Envoy.Api.V2.Listener.{FilterChain, FilterChainMatch}

    FilterChain.new(
      filter_chain_match: FilterChainMatch.new(sni_domains: sni_domains),
      filters: [default_http_conn_manager_filter(name)],
      tls_context: tls_context
    )
  end

  defp default_http_conn_manager_filter(name) do
    alias Envoy.Api.V2.Listener.Filter
    alias Envoy.Config.Filter.Network.HttpConnectionManager.V2.{HttpConnectionManager, Rds}
    import Relay.ProtobufUtil

    Filter.new(
      name: "envoy.http_connection_manager",
      config:
        mkstruct(
          HttpConnectionManager.new(
            codec_type: HttpConnectionManager.CodecType.value(:AUTO),
            route_specifier:
              {:rds,
               Rds.new(config_source: EnvoyUtil.api_config_source(), route_config_name: name)},
            stat_prefix: name,
            http_filters: [router_filter(name)],
            # FIXME: Don't do this name to atom thing
            access_log:
              String.to_existing_atom(name) |> EnvoyUtil.http_connection_manager_access_log()
          )
        )
    )
  end

  defp router_filter(name) do
    alias Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpFilter
    alias Envoy.Config.Filter.Http.Router.V2.Router
    import Relay.ProtobufUtil

    HttpFilter.new(
      name: "envoy.router",
      config:
        mkstruct(
          # FIXME: Don't do this name to atom thing
          Router.new(
            upstream_log: String.to_existing_atom(name) |> EnvoyUtil.router_upstream_log()
          )
        )
    )
  end
end
