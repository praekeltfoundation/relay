defmodule Relay.Resources.EDS do
  @moduledoc """
  Builds Envoy ClusterLoadAssignment values from cluster resources.
  """
  alias Relay.Resources.{AppPortInfo, Common}
  alias Relay.Resources.AppPortInfo

  alias Envoy.Api.V2.ClusterLoadAssignment
  alias Envoy.Api.V2.Core.Locality
  alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}

  @default_locality Locality.new(region: "default")

  @doc """
  Create ClusterLoadAssignments for the given app_port_infos.
  """
  @spec cluster_load_assignments([AppPortInfo.t()]) :: [ClusterLoadAssignment.t()]
  def cluster_load_assignments(app_port_infos) do
    Enum.map(app_port_infos, &cluster_load_assignment/1)
  end

  @spec cluster_load_assignment(AppPortInfo.t()) :: ClusterLoadAssignment.t()
  defp cluster_load_assignment(app_port_info) do
    lb_endpoints =
      app_port_info.addresses
      |> Enum.map(&lb_endpoint(&1, app_port_info.lb_endpoint_opts))

    ClusterLoadAssignment.new(
      [
        cluster_name: app_port_info.name,
        endpoints: [
          LocalityLbEndpoints.new(
            [locality: @default_locality, lb_endpoints: lb_endpoints] ++
              app_port_info.llb_endpoint_opts
          )
        ]
      ] ++ app_port_info.cla_opts
    )
  end

  @spec lb_endpoint({String.t(), integer}, keyword) :: LbEndpoint.t()
  defp lb_endpoint({address, port}, options) do
    LbEndpoint.new(
      [
        endpoint: Endpoint.new(address: Common.socket_address(address, port))
      ] ++ options
    )
  end
end
