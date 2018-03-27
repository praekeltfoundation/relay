defmodule Relay.Resources.RDS do
  @moduledoc """
  Builds Envoy RouteConfiguration values from cluster resources.
  """
  alias Relay.Resources.{AppEndpoint, LDS}

  alias Envoy.Api.V2.RouteConfiguration
  alias Envoy.Api.V2.Route.{RedirectAction, Route, RouteAction, RouteMatch, VirtualHost}

  @listeners [:http, :https]

  @doc """
  Create Clusters for the given app_endpoints.
  """
  @spec route_configurations([AppEndpoint.t()]) :: [RouteConfiguration.t()]
  def route_configurations(apps), do: Enum.map(@listeners, &route_configuration(&1, apps))

  @spec route_configuration(atom, [AppEndpoint.t()]) :: RouteConfiguration.t()
  defp route_configuration(listener, app_endpoints) do
    route_config_name = LDS.get_route_config_name(listener)

    vhosts = app_endpoints |> Enum.map(&virtual_host(listener, &1))
    RouteConfiguration.new(name: route_config_name, virtual_hosts: vhosts)
  end

  @spec virtual_host(atom, AppEndpoint.t()) :: VirtualHost.t()
  defp virtual_host(listener, app_endpoint) do
    VirtualHost.new(
      [
        # TODO: Do VirtualHost names need to be truncated?
        name: "#{listener}_#{app_endpoint.name}",
        # TODO: Validate domains
        domains: app_endpoint.domains,
        routes: app_endpoint_routes(listener, app_endpoint)
      ] ++ app_endpoint.vhost_opts
    )
  end

  @spec app_endpoint_routes(atom, AppEndpoint.t()) :: [Route.t()]
  defp app_endpoint_routes(:http, app_endpoint) do
    primary_route =
      if app_endpoint.redirect_to_https do
        https_redirect_route()
      else
        app_endpoint_route(app_endpoint)
      end

    case app_endpoint.marathon_acme_domains do
      # No marathon-acme domain--don't route to marathon-acme
      [] ->
        [primary_route]

      _ ->
        [marathon_acme_route(), primary_route]
    end
  end

  defp app_endpoint_routes(:https, app_endpoint) do
    # TODO: Do we want an HTTPS route for apps without certificates?
    [app_endpoint_route(app_endpoint)]
  end

  @spec app_endpoint_route(AppEndpoint.t()) :: Route.t()
  defp app_endpoint_route(%AppEndpoint{route_opts: options} = app_endpoint) do
    Route.new(
      [
        action: {:route, app_endpoint_route_action(app_endpoint)},
        match: app_endpoint_route_match(app_endpoint)
      ] ++ options
    )
  end

  @spec app_endpoint_route_action(AppEndpoint.t()) :: RouteAction.t()
  defp app_endpoint_route_action(%AppEndpoint{name: name, route_action_opts: options}) do
    # TODO: Does the cluster name here need to be truncated?
    RouteAction.new([cluster_specifier: {:cluster, name}] ++ options)
  end

  @spec app_endpoint_route_match(AppEndpoint.t()) :: RouteMatch.t()
  defp app_endpoint_route_match(%AppEndpoint{route_match_opts: options}) do
    # TODO: Support path-based routing
    RouteMatch.new([path_specifier: {:prefix, "/"}] ++ options)
  end

  @spec https_redirect_route() :: Route.t()
  defp https_redirect_route do
    # The HTTPS redirect route is simple and can't be customized per-app
    Route.new(
      action: {:redirect, RedirectAction.new(https_redirect: true)},
      match: RouteMatch.new(path_specifier: {:prefix, "/"})
    )
  end

  @spec marathon_acme_route() :: Route.t()
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
