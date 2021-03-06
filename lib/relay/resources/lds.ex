defmodule Relay.Resources.LDS do
  @moduledoc """
  Builds Envoy Listener values from cluster resources.
  """
  alias Relay.ProtobufUtil
  alias Relay.Resources.{CertInfo, Config}

  import Relay.Resources.Common,
    only: [api_config_source: 0, socket_address: 2, truncate_obj_name: 1]

  alias Envoy.Api.V2.Core.DataSource
  alias Envoy.Api.V2.Listener
  alias Listener.{Filter, FilterChain, FilterChainMatch, ListenerFilter}
  alias Envoy.Config.Accesslog.V2.FileAccessLog
  alias Envoy.Config.Filter.Accesslog.V2.AccessLog
  alias Envoy.Config.Filter.Http.Router.V2.Router

  alias Envoy.Config.Filter.Network.HttpConnectionManager.V2.{
    HttpConnectionManager,
    HttpFilter,
    Rds
  }

  alias Google.Protobuf.Struct

  @spec listeners([CertInfo.t()]) :: [Listener.t()]
  def listeners(cert_infos) do
    [
      listener(:http, http_filter_chains()),
      listener(
        :https,
        https_filter_chains(cert_infos),
        listener_filters: [tls_inspector_listener_filter()]
      )
    ]
  end

  @spec http_filter_chains() :: [FilterChain.t()]
  defp http_filter_chains, do: [filter_chain([http_connection_manager_filter(:http)])]

  @spec https_filter_chains([CertInfo.t()]) :: [FilterChain.t()]
  defp https_filter_chains(cert_infos) do
    # List of filters must be identical across filter chains, so create them once
    https_filters = [http_connection_manager_filter(:https)]
    Enum.map(cert_infos, &https_filter_chain(https_filters, &1))
  end

  @spec https_filter_chain([Filter.t()], CertInfo.t()) :: FilterChain.t()
  defp https_filter_chain(filters, cert_info) do
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

    filter_chain(filters, tls_context: tls_context, server_names: cert_info.domains)
  end

  @spec inline_string(String.t()) :: DataSource.t()
  defp inline_string(text), do: DataSource.new(specifier: {:inline_string, text})

  @spec filter_chain([Filter.t()], keyword) :: FilterChain.t()
  defp filter_chain(filters, options \\ []) do
    {server_names, options} = Keyword.pop(options, :server_names, [])

    # TODO: Add PROXY protocol configuration for AWS ELB support
    FilterChain.new(
      [
        filter_chain_match: FilterChainMatch.new(server_names: server_names),
        filters: filters
      ] ++ options
    )
  end

  @spec tls_inspector_listener_filter() :: ListenerFilter.t()
  defp tls_inspector_listener_filter(),
    do: ListenerFilter.new(name: "envoy.listener.tls_inspector", config: Struct.new())

  @spec listener(atom, [FilterChain.t()], keyword) :: Listener.t()
  defp listener(listener, filter_chains, options \\ []) do
    Listener.new(
      [
        name: Atom.to_string(listener) |> truncate_obj_name(),
        address: listener_address(listener),
        filter_chains: filter_chains
      ] ++ options
    )
  end

  defp listener_address(listener) do
    listen = Config.fetch_listener!(listener, :listen)
    socket_address(Keyword.fetch!(listen, :address), Keyword.fetch!(listen, :port))
  end

  @spec http_connection_manager_filter(atom) :: Filter.t()
  defp http_connection_manager_filter(listener, options \\ []) do
    Filter.new(
      name: "envoy.http_connection_manager",
      config: ProtobufUtil.mkstruct(http_connection_manager(listener, options))
    )
  end

  @spec http_connection_manager(atom, keyword) :: HttpConnectionManager.t()
  defp http_connection_manager(listener, options) do
    config = Config.fetch_listener!(listener, :http_connection_manager)
    stat_prefix = Keyword.get(config, :stat_prefix, Atom.to_string(listener))
    access_log = Keyword.get(config, :access_log) |> access_logs_from_config()

    use_remote_address = ProtobufUtil.mkvalue(Keyword.get(config, :use_remote_address))

    # TODO: Validate that the configured name is less than max_obj_name_length
    route_config_name = Config.get_listener_route_config_name(listener)

    {options, router_opts} = Keyword.pop(options, :router_opts, [])

    HttpConnectionManager.new(
      [
        codec_type: HttpConnectionManager.CodecType.value(:AUTO),
        route_specifier:
          {:rds,
           Rds.new(config_source: api_config_source(), route_config_name: route_config_name)},
        stat_prefix: stat_prefix,
        access_log: access_log,
        use_remote_address: use_remote_address,
        http_filters: [router_http_filter(listener, router_opts)]
      ] ++ options
    )
  end

  @spec router_http_filter(atom, keyword) :: HttpFilter.t()
  defp router_http_filter(listener, options) do
    HttpFilter.new(
      name: "envoy.router",
      config: ProtobufUtil.mkstruct(router(listener, options))
    )
  end

  @spec router(atom, keyword) :: Router.t()
  defp router(listener, options) do
    config = Config.fetch_listener!(listener, :router)
    upstream_log = Keyword.get(config, :upstream_log) |> access_logs_from_config()

    Router.new([upstream_log: upstream_log] ++ options)
  end

  @spec access_logs_from_config(keyword) :: [AccessLog.t()]
  defp access_logs_from_config(config) do
    # Don't configure log file if path is empty
    # TODO: Test this properly
    case Keyword.get(config, :path, "") do
      "" -> []
      path -> [file_access_log(path, Keyword.get(config, :format))]
    end
  end

  @spec file_access_log(String.t(), String.t(), keyword) :: AccessLog.t()
  defp file_access_log(path, format, options \\ []) do
    # TODO: Make it easier to configure filters (currently the only extra
    # AccessLog option).
    AccessLog.new(
      [
        name: "envoy.file_access_log",
        config: ProtobufUtil.mkstruct(FileAccessLog.new(path: path, format: format))
      ] ++ options
    )
  end
end
