defmodule Relay.EnvoyUtil do
  alias Relay.ProtobufUtil

  alias Envoy.Api.V2.Core.{Address, ApiConfigSource, ConfigSource, SocketAddress}
  alias Envoy.Config.Filter.Accesslog.V2.{AccessLog, FileAccessLog}

  @truncated_name_prefix "[...]"

  @spec api_config_source(keyword) :: ConfigSource.t()
  def api_config_source(options \\ []) do
    cluster_name = Application.fetch_env!(:relay, :envoy) |> Keyword.fetch!(:cluster_name)

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

  https://www.envoyproxy.io/docs/envoy/v1.5.0/operations/cli.html#cmdoption-max-obj-name-len
  """
  @spec truncate_obj_name(String.t()) :: String.t()
  def truncate_obj_name(name) do
    max_size = Application.fetch_env!(:relay, :envoy) |> Keyword.fetch!(:max_obj_name_length)

    case byte_size(name) do
      size when size > max_size ->
        truncated_size = max_size - byte_size(@truncated_name_prefix)
        truncated_name = name |> binary_part(size, -truncated_size)
        "#{@truncated_name_prefix}#{truncated_name}"

      _ ->
        name
    end
  end

  @spec listener_address(atom) :: Address.t()
  def listener_address(listener) do
    listen = Application.fetch_env!(:relay, :envoy) |> get_in([:listeners, listener, :listen])
    socket_address(Keyword.fetch!(listen, :address), Keyword.fetch!(listen, :port))
  end

  @spec socket_address(String.t(), :inet.port_number()) :: Address.t()
  def socket_address(address, port) do
    sock = SocketAddress.new(address: address, port_specifier: {:port_value, port})
    Address.new(address: {:socket_address, sock})
  end

  @spec http_connection_manager_access_log(atom) :: [AccessLog.t()]
  def http_connection_manager_access_log(listener) do
    Application.fetch_env!(:relay, :envoy)
    |> get_in([:listeners, listener, :http_connection_manager, :access_log])
    |> access_logs_from_config()
  end

  @spec router_upstream_log(atom) :: [AccessLog.t()]
  def router_upstream_log(listener) do
    Application.fetch_env!(:relay, :envoy)
    |> get_in([:listeners, listener, :router, :upstream_log])
    |> access_logs_from_config()
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
