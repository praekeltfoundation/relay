defmodule Relay.Marathon.Adapter do
  alias Relay.Resources.Common
  alias Relay.Marathon.{App, Task}
  alias Relay.Resources.AppPortInfo

  alias Envoy.Api.V2.ClusterLoadAssignment
  alias Envoy.Api.V2.Core.Locality
  alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}

  @default_locality Locality.new(region: "default")

  @doc """
  Create AppPortInfos for the given app. These AppPortInfos will contain only
  the basic app information required to build the various Envoy resources.
  Additional options may be specified in the `options` keyword list using the
  following keys:
  - Cluster: `:cluster_opts`
  - RouteConfiguration: Currently not supported
  - TODO: More options.
  """
  @spec app_port_infos_for_app(App.t, keyword) :: [AppPortInfo.t]
  def app_port_infos_for_app(%App{port_indices_in_group: port_indices} = app, options \\ []),
    do: Enum.map(port_indices, &app_port_info_for_app_port(app, &1, options))

  @spec app_port_info_for_app_port(App.t, non_neg_integer, keyword) :: AppPortInfo.t
  defp app_port_info_for_app_port(app, port_index, options) do
    # TODO: Validate options keys?
    %AppPortInfo{
      name: "#{app.id}_#{port_index}",
      domains: App.marathon_lb_vhost(app, port_index),
      marathon_acme_domains: App.marathon_acme_domain(app, port_index),
      redirect_to_https: App.marathon_lb_redirect_to_https?(app, port_index),
      cluster_opts: Keyword.get(options, :cluster_opts, [])
    }
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
      [
        endpoint: Endpoint.new(
          address: Common.socket_address(address, Enum.at(ports, port_index))
        )
      ] ++ options
    )
  end
end
