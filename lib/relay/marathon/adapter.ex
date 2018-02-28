defmodule Relay.Marathon.Adapter do
  alias Relay.Marathon.{App, Task}

  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment}
  alias Envoy.Api.V2.Core.{Address, ConfigSource, Locality, SocketAddress}
  alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}

  @default_max_obj_name_length 60
  @truncated_name_prefix "[...]"

  @default_locality Locality.new(region: "default")

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

    Cluster.new(
      [
        name: truncate_name(service_name, max_size),
        type: Cluster.DiscoveryType.value(:EDS),
        eds_cluster_config:
          Cluster.EdsClusterConfig.new(
            eds_config: eds_config_source,
            service_name: service_name
          )
      ] ++ options
    )
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

  @doc """
  Create a ClusterLoadAssignment for the given app, tasks, and port index. The
  ClusterLoadAssignment will have the minimum amount of options set. Additional
  options can be specified using `options`.
  """
  def app_port_cluster_load_assignment(%App{id: app_id}, tasks, port_index, options \\ []) do
    {locality_lb_endpoints_options, options} =
      Keyword.pop(options, :locality_lb_endpoints_options, [])

    ClusterLoadAssignment.new(
      [
        cluster_name: "#{app_id}_#{port_index}",
        endpoints:
          task_port_locality_lb_endpoints(tasks, port_index, locality_lb_endpoints_options)
      ] ++ options
    )
  end

  def task_port_locality_lb_endpoints(tasks, port_index, options \\ []) do
    # TODO: Support more than one locality
    {lb_endpoint_options, options} = Keyword.pop(options, :lb_endpoint_options, [])

    [
      LocalityLbEndpoints.new(
        [
          locality: @default_locality,
          lb_endpoints:
            tasks |> Enum.map(&task_port_lb_endpoint(&1, port_index, lb_endpoint_options))
        ] ++ options
      )
    ]
  end

  def task_port_lb_endpoint(%Task{address: address, ports: ports}, port_index, options \\ []) do
    LbEndpoint.new(
      [endpoint: Endpoint.new(address: socket_address(address, Enum.at(ports, port_index)))] ++
        options
    )
  end

  defp socket_address(address, port) do
    sock = SocketAddress.new(address: address, port_specifier: {:port_value, port})
    Address.new(address: {:socket_address, sock})
  end
end
