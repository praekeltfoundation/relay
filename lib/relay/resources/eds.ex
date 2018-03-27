defmodule Relay.Resources.EDS do
  @moduledoc """
  Builds Envoy ClusterLoadAssignment values from cluster resources.
  """
  alias Relay.Resources.{AppEndpoint, Common, CDS}

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

    default_locality = fetch_endpoints_config!(:locality) |> locality()
    locality = Keyword.get(app_endpoint.llb_endpoint_opts, :locality, default_locality)

    ClusterLoadAssignment.new(
      [
        cluster_name: app_endpoint.name,
        endpoints: [
          LocalityLbEndpoints.new(
            [locality: locality, lb_endpoints: lb_endpoints] ++
              app_endpoint.llb_endpoint_opts
          )
        ]
      ] ++ app_endpoint.cla_opts
    )
  end

  @spec lb_endpoint({String.t(), :inet.port_number()}, keyword) :: LbEndpoint.t()
  defp lb_endpoint({address, port}, options) do
    LbEndpoint.new(
      [
        endpoint: Endpoint.new(address: Common.socket_address(address, port))
      ] ++ options
    )
  end

  @spec endpoints_config() :: keyword
  defp endpoints_config, do: CDS.clusters_config() |> Keyword.fetch!(:endpoints)

  defp fetch_endpoints_config!(key), do: endpoints_config() |> Keyword.fetch!(key)

  @spec locality(keyword) :: Locality.t()
  defp locality(opts), do: opts |> Keyword.take([:region, :zone, :sub_zone]) |> Locality.new()
end
