defmodule Relay.Resources.CDS do
  @moduledoc """
  Builds Envoy Cluster values from cluster resources.
  """
  alias Relay.Resources.AppEndpoint
  import Relay.Resources.Common

  alias Envoy.Api.V2.Cluster

  @doc """
  Create Clusters for the given app_endpoints.
  """
  @spec clusters([AppEndpoint.t()]) :: [Cluster.t()]
  def clusters(app_endpoints) do
    Enum.map(app_endpoints, &cluster/1)
  end

  @spec cluster(AppEndpoint.t()) :: Cluster.t()
  defp cluster(%AppEndpoint{name: service_name, cluster_opts: options}) do
    default_connect_timeout = fetch_clusters_config!(:connect_timeout) |> duration()
    connect_timeout = Keyword.get(options, :connect_timeout, default_connect_timeout)

    Cluster.new(
      [
        name: truncate_obj_name(service_name),
        type: Cluster.DiscoveryType.value(:EDS),
        eds_cluster_config:
          Cluster.EdsClusterConfig.new(
            eds_config: api_config_source(),
            service_name: service_name
          ),
        connect_timeout: connect_timeout
      ] ++ options
    )
  end

  @spec clusters_config() :: keyword
  defp clusters_config(), do: fetch_envoy_config!(:clusters)

  defp fetch_clusters_config!(key), do: clusters_config() |> Keyword.fetch!(key)
end
