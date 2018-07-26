defmodule Relay.Resources.EDS do
  @moduledoc """
  Builds Envoy ClusterLoadAssignment values from cluster resources.
  """
  alias Relay.Resolver
  alias Relay.Resources.{AppEndpoint, Config}
  import Relay.Resources.Common, only: [socket_address: 2]

  alias Envoy.Api.V2.ClusterLoadAssignment
  alias Envoy.Api.V2.Core.Locality
  alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}

  @doc """
  Create ClusterLoadAssignments for the given app_endpoints.
  """
  @spec cluster_load_assignments([AppEndpoint.t()]) :: [ClusterLoadAssignment.t()]
  def cluster_load_assignments(app_endpoints) do
    Enum.map(app_endpoints, &cluster_load_assignment/1)
  end

  @spec cluster_load_assignment(AppEndpoint.t()) :: ClusterLoadAssignment.t()
  defp cluster_load_assignment(app_endpoint) do
    lb_endpoints =
      app_endpoint.addresses
      |> Enum.map(&lb_endpoint(&1, app_endpoint.lb_endpoint_opts))

    locality = Keyword.get(app_endpoint.llb_endpoint_opts, :locality, default_locality())

    ClusterLoadAssignment.new(
      [
        cluster_name: app_endpoint.name,
        endpoints: [
          LocalityLbEndpoints.new(
            [locality: locality, lb_endpoints: lb_endpoints] ++ app_endpoint.llb_endpoint_opts
          )
        ]
      ] ++ app_endpoint.cla_opts
    )
  end

  @spec lb_endpoint({String.t(), :inet.port_number()}, keyword) :: LbEndpoint.t()
  defp lb_endpoint({address, port}, options) do
    {:ok, address} = Resolver.getaddr(address)
    LbEndpoint.new([endpoint: Endpoint.new(address: socket_address(address, port))] ++ options)
  end

  @spec default_locality() :: Locality.t()
  def default_locality do
    :locality
    |> Config.fetch_endpoints!()
    |> Keyword.take([:region, :zone, :sub_zone])
    |> Locality.new()
  end
end
