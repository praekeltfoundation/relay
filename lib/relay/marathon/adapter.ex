defmodule Relay.Marathon.Adapter do
  @moduledoc """
  Turns Marathon Apps and Tasks into Relay AppEndpoints.
  """

  alias Relay.Marathon.{App, Task}
  alias Relay.Resources.AppEndpoint

  @doc """
  Create AppEndpoints for the given app and its tasks. These AppEndpoints will
  contain only the basic app information required to build the various Envoy
  resources. Additional options may be specified in the `options` keyword list
  using the following keys:
  - Cluster: `:cluster_opts`
  - RouteConfiguration: Currently not supported
  - ClusterLoadAssignment: `:cla_opts`
    - LocalityLbEndpoints: `:llb_endpoint_opts`
      - LbEndpoint: `:lb_endpoint_opts`
  """
  @spec app_endpoints_for_app(App.t(), [Task.t()], keyword) :: [AppEndpoint.t()]
  def app_endpoints_for_app(%App{port_indices: port_indices} = app, tasks, options \\ []),
    do: Enum.map(port_indices, &app_endpoint_for_app_port(app, tasks, &1, options))

  @spec app_endpoint_for_app_port(App.t(), [Task.t()], non_neg_integer, keyword) ::
          AppEndpoint.t()
  defp app_endpoint_for_app_port(app, tasks, port_index, options) do
    # TODO: Validate options keys?
    %AppEndpoint{
      name: "#{app.id}_#{port_index}",
      domains: App.marathon_lb_vhost(app, port_index),
      addresses: Enum.map(tasks, &{&1.address, Enum.at(&1.ports, port_index)}),
      marathon_acme_domains: App.marathon_acme_domain(app, port_index),
      redirect_to_https: App.marathon_lb_redirect_to_https?(app, port_index),
      cluster_opts: Keyword.get(options, :cluster_opts, []),
      cla_opts: Keyword.get(options, :cla_opts, []),
      llb_endpoint_opts: Keyword.get(options, :llb_endpoint_opts, []),
      lb_endpoint_opts: Keyword.get(options, :lb_endpoint_opts, [])
    }
  end
end
