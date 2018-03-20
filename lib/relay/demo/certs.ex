defmodule Relay.Demo.Certs do
  alias Relay.{Certs, EnvoyUtil, Store}

  @demo_pem """
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpQIBAAKCAQEA5kY2oNwb6zoGegDP3a5nSjXHMz8yXAG/C9S33kQLgw+CNHHa
  G9NAhFTVUt/0ChBu546cSU3276+6ww8zN15bB8IkgdNmaN1ext/7vYUNZNL7As3U
  QzXnh+SSdxWd7a7S6Qt/qs6Rvkn42eln1Kyqgiodg9n6aZaawlGtTFT+vvaG+AR0
  zHOjF560z40rV0D6SgXF7pPuW/8J8ySskxy8iNOZY1bn7JJjJvbPmC+hn1N2EYJo
  uTkZI/aHw0NRxXGhePY4IP2VnALnVPk1yX/QjyfIEutsrEulk9yUnMyPwo04inJZ
  3YM/cClQuk6h7Xi3jUnZODgnMN5e9dsQ2A0qwwIDAQABAoIBAQDj8r9jD2CHwyHk
  JeefD2TqHkA5p6aHU6c14/W7jWpD69c9aTK6dq2YEY42gsFGMSxIBnEJU6dNb4yW
  SPavKbU9Ad83sPfgeLq4bcL6wboXg469INmtSrAOYqLmRTzXq0bXMO3JPMEjOICh
  3h5Ndjs3rM8Y1W/AlDhQgZ/mPwEKMIj1xwQx69216sBDNuqIJDW8WHrdijmJR9DX
  KXqrqavb9B5lohfvLQUYJ5J7qNeoczBINjdLpjGeOkupn3ayn1Ytstek6yQhEuYo
  AYh0IX0iysBNeriLJ+n0BajyFZUvKeKWN5CtKLepW56hedt6beNHNva2bMg/TGPl
  nt1qBTkxAoGBAP8MXWCSl8aBfyp6bOS/apUEBblHDrG7u+wwtSMRd5y+HNAZVjX/
  un3tpchdUaN2SkmVL8JZ5NbJca/H8E5Db3Kg/tMR8/8jJYmJdIFGD3emNLLJx29J
  mg58lkbKv4bcXRuuIX/Fu9lLb0mDFViaNavqg1/FFhKAlFPlveBig4wLAoGBAOci
  Lub0Bn0ElEeTy+oFwnn23oPbSM2B2Dmkc8yt8iszjH69xBvsQ3GluEMlVxWBBH+u
  vVRQlrWp1LdTFXxR3NWbhU0feT23ewOdxOPH0fezrKNMl+GZEYezmlXS+OKaj8Yc
  OLTa59QOczprVltuupmfSTkepG2TuKRwH1LvrFcpAoGBALH4S9ROlpAS3syiXwgD
  tfjDtMbDmbJWANzgZBVTY/bBBlQDyg+mIdkrkmpNC+GXcmEENC5XEgL60FTLnJjQ
  H52KUCayuWMIgHIHs39dhv+Dv/QeLwcuAc0oDKjbY2hUrrfY+1EwhlMrez19tdB8
  0wTigMe8PBmvFVGx15wSwh5fAoGBAINDO4W4AlNPnXJE8mJ2YOrpE5eommDzo7ug
  tI8CHm0AeoKj/NKqy+an6cxgUWOKAOcOcsGGfwCucXqneaU/zH2XNA4HmNA++mKk
  X+PIYGsfJCUdY4ggaP87NaQWC3iNtKca8e1sAIrCphgAS2vjp5+FAY2p5FHCufLR
  Jkjwilx5AoGAe+bfbhi8E/5vFT44O15HyQ5H8Vhbhvjs4JiI2f/qTFPb6LVhrr4n
  +d/VQiM3d/tk1S56J3mKa+4JKrNDtjBICmzc0HM704TyOJ/Njme7pAG/m454t+VE
  I5J7mPqmYEY+KZ/AdASqyBuMRSXy24z48OlwrakXWdE6lshwxS60BHA=
  -----END RSA PRIVATE KEY-----
  -----BEGIN CERTIFICATE-----
  MIIDDDCCAfSgAwIBAgIJAMtqalFrtFNjMA0GCSqGSIb3DQEBBQUAMBsxGTAXBgNV
  BAMMEGRlbW8uZXhhbXBsZS5jb20wHhcNMTgwMzEyMTMyMzMxWhcNMjgwMzA5MTMy
  MzMxWjAbMRkwFwYDVQQDDBBkZW1vLmV4YW1wbGUuY29tMIIBIjANBgkqhkiG9w0B
  AQEFAAOCAQ8AMIIBCgKCAQEA5kY2oNwb6zoGegDP3a5nSjXHMz8yXAG/C9S33kQL
  gw+CNHHaG9NAhFTVUt/0ChBu546cSU3276+6ww8zN15bB8IkgdNmaN1ext/7vYUN
  ZNL7As3UQzXnh+SSdxWd7a7S6Qt/qs6Rvkn42eln1Kyqgiodg9n6aZaawlGtTFT+
  vvaG+AR0zHOjF560z40rV0D6SgXF7pPuW/8J8ySskxy8iNOZY1bn7JJjJvbPmC+h
  n1N2EYJouTkZI/aHw0NRxXGhePY4IP2VnALnVPk1yX/QjyfIEutsrEulk9yUnMyP
  wo04inJZ3YM/cClQuk6h7Xi3jUnZODgnMN5e9dsQ2A0qwwIDAQABo1MwUTALBgNV
  HQ8EBAMCBDAwEwYDVR0lBAwwCgYIKwYBBQUHAwEwLQYDVR0RBCYwJIIQZGVtby5l
  eGFtcGxlLmNvbYIQZGVtby5leGFtcGxlLm5ldDANBgkqhkiG9w0BAQUFAAOCAQEA
  MquJ+uO6QbPG3vc6yXcjUNGWlBt53FfcbA/7lWwLVbwlgMVTY5AgDMT0beI31VMz
  6zERopz0Tmg3sWSVOfs/VF/bTx1niOD79a2mjRc/9WVCGZFqa/MDoqHScPgtqnnn
  UX+XhoaXDrpCg5T6B+p9zq5kwuE8YrLcKvk9usgz3b3Ou2BuT7yk8LlNrxzgOAez
  6uj9wp11NUk/tAsZ1otJDCls9qrb7Uw8FyvpCkMmjcZh8awLOez15r4pyLvbzsrJ
  ZiGzz2MKPBQjWDw3TPI84p+DVngyFxwlMygy2vNFPADKK3QmFMZl/rxXLZUP+sC2
  vRZqyTA6pzT3ZUMj0MJ5XA==
  -----END CERTIFICATE-----
  """

  use GenServer

  defmodule State do
    defstruct delay: 1_000, version: 1
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def update_state(), do: GenServer.call(__MODULE__, :update_state)

  # Callbacks

  def init(_args) do
    # TODO: Make delay configurable.
    send(self(), :scheduled_update)
    {:ok, %State{}}
  end

  def handle_call(:update_state, _from, state) do
    {:reply, :ok, update_state(state)}
  end

  def handle_info(:scheduled_update, state) do
    Process.send_after(self(), :scheduled_update, state.delay)
    {:noreply, update_state(state)}
  end

  # Internals

  defp update_state(state) do
    v = "#{state.version}"
    Store.update(Store, :lds, v, listeners())
    %{state | version: state.version + 1}
  end

  defp router_filter(name) do
    alias Envoy.Config.Filter.Network.HttpConnectionManager.V2.HttpFilter
    alias Envoy.Config.Filter.Http.Router.V2.Router
    import Relay.ProtobufUtil
    HttpFilter.new(
      name: "envoy.router",
      config: mkstruct(
        # FIXME: Don't do this name to atom thing
        Router.new(upstream_log: String.to_existing_atom(name) |> EnvoyUtil.router_upstream_log())
      )
    )
  end

  defp default_http_conn_manager_filter(name) do
    alias Envoy.Api.V2.Listener.Filter
    alias Envoy.Config.Filter.Network.HttpConnectionManager.V2.{HttpConnectionManager, Rds}
    import Relay.ProtobufUtil

    Filter.new(
      name: "envoy.http_connection_manager",
      config: mkstruct(
        HttpConnectionManager.new(
          codec_type: HttpConnectionManager.CodecType.value(:AUTO),
          route_specifier: {:rds, Rds.new(
            config_source: EnvoyUtil.api_config_source(), route_config_name: name)},
          stat_prefix: name,
          http_filters: [router_filter(name)],
          # FIXME: Don't do this name to atom thing
          access_log:
            String.to_existing_atom(name) |> EnvoyUtil.http_connection_manager_access_log()
        )
      )
    )
  end

  defp filter_chain(name, {tls_context, sni_domains} \\ {nil, []}) do
    alias Envoy.Api.V2.Listener.{FilterChain, FilterChainMatch}
    FilterChain.new(
      filter_chain_match: FilterChainMatch.new(sni_domains: sni_domains),
      filters: [default_http_conn_manager_filter(name)],
      tls_context: tls_context
    )
  end

  defp inline_pem(pem_data) do
    alias Envoy.Api.V2.Core.DataSource
    DataSource.new(specifier: {:inline_string, Certs.pem_encode(pem_data)})
  end

  defp https_filter_chain(cert_bundle) do
    alias Envoy.Api.V2.Auth
    {:ok, key} = Certs.get_key(cert_bundle)
    certs = Certs.get_certs(cert_bundle)
    sni_domains = Certs.get_end_entity_hostnames(certs)
    tls_context = Auth.DownstreamTlsContext.new(
      common_tls_context: Auth.CommonTlsContext.new(
        alpn_protocols: ["h2,http/1.1"],
        tls_certificates: [
          Auth.TlsCertificate.new(
            certificate_chain: inline_pem(certs),
            private_key: inline_pem(key)
          )
        ]
      )
    )
    filter_chain("https", {tls_context, sni_domains})
  end

  def listeners do
    https_filter_chains = Enum.map([@demo_pem], &https_filter_chain/1)
    [
      EnvoyUtil.listener(:http, [filter_chain("http")]),
      EnvoyUtil.listener(:https, https_filter_chains),
    ]
  end
end
