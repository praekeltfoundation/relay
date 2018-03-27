defmodule Relay.Resources.CDS do
  @moduledoc """
  Builds Envoy Cluster values from cluster resources.
  """
  alias Relay.Resources.AppEndpoint
  import Relay.Resources.Common

  alias Envoy.Api.V2.Cluster

  alias Google.Protobuf.Duration

  @default_cluster_connect_timeout Duration.new(seconds: 5)

  @doc """
  Create Clusters for the given app_endpoints.
  """
  @spec clusters([AppEndpoint.t()]) :: [Cluster.t()]
  def clusters(app_endpoints) do
    Enum.map(app_endpoints, &cluster/1)
  end

  @spec cluster(AppEndpoint.t()) :: Cluster.t()
  defp cluster(%AppEndpoint{name: service_name, cluster_opts: options}) do
    Cluster.new(
      [
        name: truncate_obj_name(service_name),
        type: Cluster.DiscoveryType.value(:EDS),
        eds_cluster_config:
          Cluster.EdsClusterConfig.new(
            eds_config: api_config_source(),
            service_name: service_name
          ),
        connect_timeout: Keyword.get(options, :connect_timeout, @default_cluster_connect_timeout)
      ] ++ options
    )
  end
end
