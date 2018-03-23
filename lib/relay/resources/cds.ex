defmodule Relay.Resources.CDS do
  @moduledoc """
  Builds Envoy Cluster values from cluster resources.
  """
  alias Relay.Resources.{AppPortInfo, Common}

  alias Envoy.Api.V2.Cluster

  alias Google.Protobuf.Duration

  @default_cluster_connect_timeout Duration.new(seconds: 5)

  @doc """
  Create Clusters for the given app_port_infos.
  """
  @spec clusters([AppPortInfo.t()]) :: [Cluster.t()]
  def clusters(app_port_infos) do
    Enum.map(app_port_infos, &app_port_info_cluster/1)
  end

  @spec app_port_info_cluster(AppPortInfo.t()) :: Cluster.t()
  defp app_port_info_cluster(%AppPortInfo{name: service_name, cluster_opts: options}) do
    Cluster.new(
      [
        name: Common.truncate_obj_name(service_name),
        type: Cluster.DiscoveryType.value(:EDS),
        eds_cluster_config:
          Cluster.EdsClusterConfig.new(
            eds_config: Common.api_config_source(),
            service_name: service_name
          ),
        connect_timeout: Keyword.get(options, :connect_timeout, @default_cluster_connect_timeout)
      ] ++ options
    )
  end
end
