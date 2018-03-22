defmodule Relay.EnvoyUtil do
  alias Relay.ProtobufUtil

  alias Envoy.Api.V2.Listener
  alias Envoy.Api.V2.Listener.{Filter, FilterChain}
  alias Envoy.Api.V2.Core.{Address, ApiConfigSource, ConfigSource, SocketAddress}
  alias Envoy.Config.Filter.Accesslog.V2.{AccessLog, FileAccessLog}
  alias Envoy.Config.Filter.Http.Router.V2.Router

  alias Envoy.Config.Filter.Network.HttpConnectionManager.V2.{
    HttpConnectionManager,
    HttpFilter,
    Rds
  }

  @truncated_name_prefix "[...]"

  @spec envoy_config() :: keyword
  defp envoy_config, do: Application.fetch_env!(:relay, :envoy)

  defp fetch_envoy_config!(key), do: envoy_config() |> Keyword.fetch!(key)

  @spec api_config_source(keyword) :: ConfigSource.t()
  def api_config_source(options \\ []) do
    cluster_name = fetch_envoy_config!(:cluster_name)

    ConfigSource.new(
      config_source_specifier:
        {:api_config_source,
         ApiConfigSource.new(
           [
             api_type: ApiConfigSource.ApiType.value(:GRPC),
             cluster_names: [cluster_name]
           ] ++ options
         )}
    )
  end

  @doc """
  Truncate an object name to within the Envoy limit. Envoy has limits on the
  size of the value for the name field for Cluster/RouteConfiguration/Listener
  objects.

  https://www.envoyproxy.io/docs/envoy/v1.6.0/operations/cli.html#cmdoption-max-obj-name-len
  """
  @spec truncate_obj_name(String.t()) :: String.t()
  def truncate_obj_name(name) do
    max_size = fetch_envoy_config!(:max_obj_name_length)

    case byte_size(name) do
      size when size > max_size ->
        truncated_size = max_size - byte_size(@truncated_name_prefix)
        truncated_name = name |> binary_part(size, -truncated_size)
        "#{@truncated_name_prefix}#{truncated_name}"

      _ ->
        name
    end
  end

  @spec listener(atom, [FilterChain.t()], keyword) :: Listener.t()
  def listener(listener, filter_chains, options \\ []) do
    Listener.new(
      [
        name: Atom.to_string(listener) |> truncate_obj_name(),
        address: listener_address(listener),
        filter_chains: filter_chains
      ] ++ options
    )
  end

  @spec listener_config(atom) :: keyword
  defp listener_config(listener), do: fetch_envoy_config!(:listeners) |> Keyword.fetch!(listener)

  defp get_listener_config(listener, key, default),
    do: listener_config(listener) |> Keyword.get(key, default)

  defp fetch_listener_config!(listener, key), do: listener_config(listener) |> Keyword.fetch!(key)

  @spec listener_address(atom) :: Address.t()
  defp listener_address(listener) do
    listen = fetch_listener_config!(listener, :listen)
    socket_address(Keyword.fetch!(listen, :address), Keyword.fetch!(listen, :port))
  end

  @spec socket_address(String.t(), :inet.port_number()) :: Address.t()
  def socket_address(address, port) do
    sock = SocketAddress.new(address: address, port_specifier: {:port_value, port})
    Address.new(address: {:socket_address, sock})
  end

  @spec http_connection_manager_filter(atom) :: Filter.t()
  def http_connection_manager_filter(listener, options \\ []) do
    Filter.new(
      name: "envoy.http_connection_manager",
      config: ProtobufUtil.mkstruct(http_connection_manager(listener, options))
    )
  end

  @spec http_connection_manager(atom, keyword) :: HttpConnectionManager.t()
  defp http_connection_manager(listener, options) do
    config = fetch_listener_config!(listener, :http_connection_manager)

    default_name = Atom.to_string(listener)
    route_config_name = get_listener_config(listener, :route_config_name, default_name)
    stat_prefix = Keyword.get(config, :stat_prefix, default_name)

    access_log = Keyword.get(config, :access_log) |> access_logs_from_config()

    {options, router_opts} = Keyword.pop(options, :router_opts, [])

    HttpConnectionManager.new(
      [
        codec_type: HttpConnectionManager.CodecType.value(:AUTO),
        route_specifier:
          {:rds,
           Rds.new(config_source: api_config_source(), route_config_name: route_config_name)},
        stat_prefix: stat_prefix,
        access_log: access_log,
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
    config = fetch_listener_config!(listener, :router)
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
  def file_access_log(path, format, options \\ []) do
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
