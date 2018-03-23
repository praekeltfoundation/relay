defmodule Relay.Resources.RDS do
  @moduledoc """
  Builds Envoy RouteConfiguration values from cluster resources.
  """
  alias Relay.Resources.AppPortInfo

  alias Envoy.Api.V2.RouteConfiguration
  alias Envoy.Api.V2.Route.{RedirectAction, Route, RouteAction, RouteMatch, VirtualHost}

  @listeners [:http, :https]

  @doc """
  Create Clusters for the given app_port_infos.
  """
  @spec routes([AppPortInfo.t()]) :: [RouteConfiguration.t()]
  def routes(apps), do: Enum.map(@listeners, &app_infos_route_configuration(&1, apps))

  @spec app_infos_route_configuration(atom, [AppPortInfo.t()]) :: RouteConfiguration.t()
  defp app_infos_route_configuration(listener, app_infos) do
    # TODO: Use route config name from config
    name = Atom.to_string(listener)
    vhosts = app_infos |> Enum.map(&app_info_virtual_host(listener, &1))
    RouteConfiguration.new(name: name, virtual_hosts: vhosts)
  end

  @spec app_info_virtual_host(atom, AppPortInfo.t()) :: VirtualHost.t()
  defp app_info_virtual_host(listener, app_info) do
    VirtualHost.new(
      # TODO: Do VirtualHost names need to be truncated?
      name: "#{listener}_#{app_info.name}",
      # TODO: Validate domains
      domains: app_info.domains,
      routes: app_info_routes(listener, app_info)
    )
  end

  @spec app_info_routes(atom, AppPortInfo.t()) :: [Route.t()]
  defp app_info_routes(:http, app_info) do
    primary_route_action =
      if app_info.redirect_to_https do
        {:redirect, RedirectAction.new(https_redirect: true)}
      else
        # TODO: Does the cluster name here need to be truncated?
        {:route, RouteAction.new(cluster_specifier: {:cluster, app_info.name})}
      end

    primary_route =
      Route.new(
        action: primary_route_action,
        # TODO: Support path-based routing
        match: RouteMatch.new(path_specifier: {:prefix, "/"})
      )

    case app_info.marathon_acme_domains do
      # No marathon-acme domain--don't route to marathon-acme
      [] ->
        [primary_route]

      _ ->
        [marathon_acme_route(), primary_route]
    end
  end

  defp app_info_routes(:https, app_info) do
    # TODO: Do we want an HTTPS route for apps without certificates?
    [
      Route.new(
        # TODO: Does the cluster name here need to be truncated?
        action: {:route, RouteAction.new(cluster_specifier: {:cluster, app_info.name})},
        # TODO: Support path-based routing
        match: RouteMatch.new(path_specifier: {:prefix, "/"})
      )
    ]
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
