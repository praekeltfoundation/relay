defmodule Relay.Marathon.Adapter do
  alias Relay.EnvoyUtil
  alias Relay.Marathon.{App, Task, Networking}

  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment, RouteConfiguration}
  alias Envoy.Api.V2.Core.{Address, ConfigSource, Locality, SocketAddress}
  alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}
  alias Envoy.Api.V2.Route.{RedirectAction, Route, RouteAction, RouteMatch, VirtualHost}

  alias Google.Protobuf.Duration

  @default_max_obj_name_length 60
  @truncated_name_prefix "[...]"

  @default_cluster_connect_timeout Duration.new(seconds: 5)
  @default_locality Locality.new(region: "default")

  @listeners [:http, :https]

  @doc """
  Create Clusters for the given app. The Clusters will have the minimum amount
  of options set but will be Clusters with EDS endpoint discovery. Additional
  options can be specified using `options`.
  """
  @spec app_clusters(App.t, keyword) :: [Cluster.t]
  def app_clusters(%App{port_indices_in_group: port_indices_in_group} = app, options \\ []) do
    eds_config_source = EnvoyUtil.api_config_source()

    port_indices_in_group
    |> Enum.map(&app_port_cluster(app, &1, eds_config_source, options))
  end

  @spec app_port_cluster(App.t, non_neg_integer, ConfigSource.t, keyword) :: Cluster.t
  defp app_port_cluster(
        %App{id: app_id},
        port_index,
        %ConfigSource{} = eds_config_source,
        options
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
          ),
        connect_timeout: Keyword.get(options, :connect_timeout, @default_cluster_connect_timeout)
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
  @spec truncate_name(String.t, pos_integer) :: String.t
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
  Create ClusterLoadAssignments for the given app and tasks. The
  ClusterLoadAssignments will have the minimum amount of options set.

  Additional options can be specified using `options` and options for nested
  types are nested within that:
  - ClusterLoadAssignment: `options`
  - LocalityLbEndpoints: `options.locality_lb_endpoints_opts`
  - LbEndpoint: `options.locality_lb_endpoints_opts.lb_endpoint_opts`
  """
  @spec app_cluster_load_assignments(App.t, [Task.t], keyword) :: [ClusterLoadAssignment.t]
  def app_cluster_load_assignments(
        %App{port_indices_in_group: port_indices_in_group} = app,
        tasks,
        options \\ []
      ) do
    port_indices_in_group
    |> Enum.map(&app_port_cluster_load_assignment(app, tasks, &1, options))
  end

  @spec app_port_cluster_load_assignment(App.t, [Task.t], non_neg_integer, keyword) ::
          ClusterLoadAssignment.t
  defp app_port_cluster_load_assignment(%App{id: app_id}, tasks, port_index, options) do
    {llbe_opts, options} = Keyword.pop(options, :locality_lb_endpoints_opts, [])

    ClusterLoadAssignment.new(
      [
        cluster_name: "#{app_id}_#{port_index}",
        endpoints: task_port_locality_lb_endpoints(tasks, port_index, llbe_opts)
      ] ++ options
    )
  end

  @spec task_port_locality_lb_endpoints([Task.t], non_neg_integer, keyword) ::
          [LocalityLbEndpoints.t]
  def task_port_locality_lb_endpoints(tasks, port_index, options \\ []) do
    # TODO: Support more than one locality
    {lb_endpoint_opts, options} = Keyword.pop(options, :lb_endpoint_opts, [])

    [
      LocalityLbEndpoints.new(
        [
          locality: @default_locality,
          lb_endpoints:
            tasks |> Enum.map(&task_port_lb_endpoint(&1, port_index, lb_endpoint_opts))
        ] ++ options
      )
    ]
  end

  @spec task_port_lb_endpoint(Task.t, non_neg_integer, keyword) :: LbEndpoint.t
  def task_port_lb_endpoint(%Task{address: address, ports: ports}, port_index, options \\ []) do
    LbEndpoint.new(
      [endpoint: Endpoint.new(address: socket_address(address, Enum.at(ports, port_index)))] ++
        options
    )
  end

  @spec socket_address(String.t, Networking.port_number) :: Address.t
  defp socket_address(address, port) do
    sock = SocketAddress.new(address: address, port_specifier: {:port_value, port})
    Address.new(address: {:socket_address, sock})
  end

  @doc """
  Create RouteConfigurations for the given apps. The RouteConfigurations will
  have the minimum amount of options set.

  Additional options can be specified using `options` and options for nested
  types are nested within that:
  - RouteConfiguration: {`http_opts`|`https_opts`}
  - VirtualHost: `{`http_opts`|`https_opts`}.virtual_host_opts`
  - Route: `{`http_opts`|`https_opts`}.virtual_host_opts.route_opts`
  - RouteAction: `{`http_opts`|`https_opts`}.virtual_host_opts.route_opts.action_opts`
  - RouteMatch: `{`http_opts`|`https_opts`}.virtual_host_opts.route_opts.match_opts`
  """
  @spec apps_route_configurations([App.t], keyword) :: [RouteConfiguration.t]
  def apps_route_configurations(apps, options \\ []) do
    Enum.map(@listeners, fn listener ->
      {config_opts, _options} = Keyword.pop(options, :"#{listener}_opts", [])

      apps_route_configuration(listener, apps, config_opts)
    end)
  end

  @spec apps_route_configuration(atom, [App.t], keyword) :: RouteConfiguration.t
  defp apps_route_configuration(listener, apps, options) do
    {name, options} = Keyword.pop(options, :name, Atom.to_string(listener))
    {virtual_host_opts, options} = Keyword.pop(options, :virtual_host_opts, [])

    RouteConfiguration.new(
      [
        name: name,
        virtual_hosts: apps |> Enum.flat_map(&app_virtual_hosts(listener, &1, virtual_host_opts))
      ] ++ options
    )
  end

  @doc """
  Create VirtualHosts for the given listener and app. The VirtualHosts will have
  the minimum amount of options set.

  Additional options can be specified using `options` and options for nested
  types are nested within that:
  - VirtualHost: `options`
  - Route: `options.route_opts`
  - RouteAction: `options.route_opts.action_opts`
  - RouteMatch: `options.route_opts.match_opts`
  """
  @spec app_virtual_hosts(atom, App.t, keyword) :: [VirtualHost.t]
  def app_virtual_hosts(
        listener,
        %App{port_indices_in_group: port_indices_in_group} = app,
        options \\ []
      ) do
    if not listener in @listeners,
      do: raise(ArgumentError,
        "Unknown listener '#{listener}'. Known listeners: #{Enum.join(@listeners, ", ")}")

    port_indices_in_group
    |> Enum.map(&app_port_virtual_host(listener, app, &1, options))
  end

  @spec app_port_virtual_host(atom, App.t, non_neg_integer, keyword) :: VirtualHost.t
  defp app_port_virtual_host(listener, %App{id: app_id} = app, port_index, options) do
    {route_opts, options} = Keyword.pop(options, :route_opts, [])

    VirtualHost.new(
      [
        # TODO: Do VirtualHost names need to be truncated?
        name: "#{listener}_#{app_id}_#{port_index}",
        # TODO: Validate domains
        domains: App.marathon_lb_vhost(app, port_index),
        routes: app_port_routes(listener, app, port_index, route_opts)
      ] ++ options
    )
  end

  @spec app_port_routes(atom, App.t, non_neg_integer, keyword) :: [Route.t]
  defp app_port_routes(:http, %App{id: app_id} = app, port_index, options) do
    {action_opts, options} = Keyword.pop(options, :action_opts, [])

    primary_route_action =
      if App.marathon_lb_redirect_to_https?(app, port_index) do
        {:redirect, RedirectAction.new(https_redirect: true)}
      else
        {:route,
         RouteAction.new(
           [
             # TODO: Does the cluster name here need to be truncated?
             cluster_specifier: {:cluster, "#{app_id}_#{port_index}"}
           ] ++ action_opts
         )}
      end

    {match_opts, options} = Keyword.pop(options, :match_opts, [])

    primary_route =
      Route.new(
        [
          action: primary_route_action,
          # TODO: Support path-based routing
          match: RouteMatch.new([path_specifier: {:prefix, "/"}] ++ match_opts)
        ] ++ options
      )

    case App.marathon_acme_domain(app, port_index) do
      # No marathon-acme domain--don't route to marathon-acme
      [] -> [primary_route]
      _ -> [marathon_acme_route(), primary_route]
    end
  end

  defp app_port_routes(:https, %App{id: app_id}, port_index, options) do
    # TODO: Do we want an HTTPS route for apps without certificates?
    {action_opts, options} = Keyword.pop(options, :action_opts, [])
    {match_opts, options} = Keyword.pop(options, :match_opts, [])

    [
      Route.new(
        [
          action:
            {:route,
             RouteAction.new(
               [
                 # TODO: Does the cluster name here need to be truncated?
                 cluster_specifier: {:cluster, "#{app_id}_#{port_index}"}
               ] ++ action_opts
             )},
          # TODO: Support path-based routing
          match: RouteMatch.new([path_specifier: {:prefix, "/"}] ++ match_opts)
        ] ++ options
      )
    ]
  end

  @spec marathon_acme_route() :: Route.t
  defp marathon_acme_route do
    config = Application.fetch_env!(:relay, :marathon_acme)
    # TODO: Does the cluster name here need to be truncated?
    cluster = "#{Keyword.fetch!(config, :app_id)}_#{Keyword.fetch!(config, :port_index)}"
    Route.new(
      action: {:route, RouteAction.new(cluster_specifier: {:cluster, cluster})},
      match: RouteMatch.new(path_specifier: {:prefix, "/.well-known/acme-challenge/"})
    )
  end
end
