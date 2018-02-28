defmodule Relay.Marathon.Adapter do
  alias Relay.Marathon.App

  alias Envoy.Api.V2.Cluster
  alias Envoy.Api.V2.Core.ConfigSource

  @default_max_obj_name_length 60
  @truncated_name_prefix "[...]"

  @doc """
  Create a Cluster for the given app and port index. The Cluster will have the
  minimum amount of options set but will be a Cluster with EDS endpoint
  discovery. Additional options can be specified using `options`.
  """
  def app_port_cluster(
        %App{id: app_id} = _app,
        port_index,
        %ConfigSource{} = eds_config_source,
        options \\ []
      ) do
    service_name = "#{app_id}_#{port_index}"
    {max_size, options} = max_obj_name_length(options)

    kw = [
      name: truncate_name(service_name, max_size),
      type: Cluster.DiscoveryType.value(:EDS),
      eds_cluster_config:
        Cluster.EdsClusterConfig.new(
          eds_config: eds_config_source,
          service_name: service_name
        )
    ]

    Cluster.new(Keyword.merge(options, kw))
  end

  # Pop the max_obj_name_length keyword from the given keyword list.
  defp max_obj_name_length(options),
    do: Keyword.pop(options, :max_obj_name_length, @default_max_obj_name_length)

  @doc """
  Truncate a name to a certain byte size. Envoy has limits on the size of the
  value for the name field for Cluster/RouteConfiguration/Listener objects.

  https://www.envoyproxy.io/docs/envoy/v1.5.0/operations/cli.html#cmdoption-max-obj-name-len
  """
  def truncate_name(name, max_size) do
    if byte_size(@truncated_name_prefix) > max_size,
      do: raise(ArgumentError, "`max_size` must be larger than the prefix length")

    case byte_size(name) do
      size when size > max_size ->
        truncated_size = max_size - byte_size(@truncated_name_prefix)
        truncated_name = name |> binary_part(size, -truncated_size)
        "#{@truncated_name_prefix}#{truncated_name}"

      _ ->
        name
    end
  end
end
