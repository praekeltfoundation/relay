defmodule Relay.Resources.Common do
  alias Envoy.Api.V2.Core.{Address, ApiConfigSource, ConfigSource, SocketAddress}

  @truncated_name_prefix "[...]"

  @spec envoy_config() :: keyword
  def envoy_config, do: Application.fetch_env!(:relay, :envoy)

  @spec fetch_envoy_config!(atom) :: any
  def fetch_envoy_config!(key), do: envoy_config() |> Keyword.fetch!(key)

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

  @spec socket_address(String.t(), :inet.port_number()) :: Address.t()
  def socket_address(address, port) do
    sock = SocketAddress.new(address: address, port_specifier: {:port_value, port})
    Address.new(address: {:socket_address, sock})
  end
end
