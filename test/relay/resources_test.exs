defmodule Relay.ResourcesTest do
  use ExUnit.Case, async: true

  alias Relay.{Publisher, Resources}
  alias Relay.Resources.{AppEndpoint, CertInfo, LDS, CDS, RDS, EDS}

  @cert_info_1 %CertInfo{
    domains: ["example.com"],
    key: "PEM key for example.com",
    cert_chain: "PEM certs for example.com"
  }

  @cert_info_2 %CertInfo{
    domains: ["example.net", "www.example.net"],
    key: "PEM key for example.net",
    cert_chain: "PEM certs for example.net"
  }

  @app_endpoint_1 %AppEndpoint{
    name: "/mc2_0",
    domains: ["example.com"],
    addresses: [{"10.70.4.100", 15979}, {"10.70.4.101", 15980}]
  }

  @app_endpoint_2 %AppEndpoint{
    name: "/mc2_0",
    domains: ["example.net"],
    addresses: [{"10.70.4.102", 15981}]
  }

  setup do
    {:ok, pub} = start_supervised(Publisher)
    {:ok, res} = start_supervised({Resources, publisher: pub})
    %{pub: pub, res: res}
  end

  defp get_pub_state(pub, xds) do
    {:ok, resources} = GenServer.call(pub, {:_get_resources, xds})
    {resources.version_info, resources.resources}
  end

  defp assert_empty_state(pub, resources),
    do: Enum.each(resources, &assert(get_pub_state(pub, &1) == {"", []}))

  defp assert_lds(pub, version, cert_infos),
    do: assert(get_pub_state(pub, :lds) == {version, LDS.listeners(cert_infos)})

  defp assert_cds(pub, version, app_endpoints),
    do: assert(get_pub_state(pub, :cds) == {version, CDS.clusters(app_endpoints)})

  defp assert_rds(pub, version, app_endpoints),
    do: assert(get_pub_state(pub, :rds) == {version, RDS.routes(app_endpoints)})

  defp assert_eds(pub, version, app_endpoints),
    do: assert(get_pub_state(pub, :eds) == {version, EDS.cluster_load_assignments(app_endpoints)})

  test "does not push empty state at startup", %{pub: pub, res: res} do
    # The publisher has not received any state.
    assert_empty_state(pub, [:lds, :cds, :rds, :eds])

    # Send a no-op SNI cert update to trigger a push.
    :ok = Resources.update_sni_certs(res, "1", [])
    # The publisher has received HTTP and HTTPS listeners, but no other state.
    assert_lds(pub, "1", [])
    assert_empty_state(pub, [:cds, :rds, :eds])
  end

  test "pushes listeners with cert info in HTTPS filter chains", %{pub: pub, res: res} do
    assert_empty_state(pub, [:lds])

    # Add two certs.
    :ok = Resources.update_sni_certs(res, "1", [@cert_info_1, @cert_info_2])
    assert_lds(pub, "1", [@cert_info_1, @cert_info_2])

    # Remove one cert.
    :ok = Resources.update_sni_certs(res, "2", [@cert_info_1])
    assert_lds(pub, "2", [@cert_info_1])
  end

  test "pushes clusters, routes, endpoints", %{pub: pub, res: res} do
    assert_empty_state(pub, [:cds, :rds, :eds])

    # Add two app endpoints.
    :ok = Resources.update_app_endpoints(res, "1", [@app_endpoint_1, @app_endpoint_2])
    assert_cds(pub, "1", [@app_endpoint_1, @app_endpoint_2])
    assert_rds(pub, "1", [@app_endpoint_1, @app_endpoint_2])
    assert_eds(pub, "1", [@app_endpoint_1, @app_endpoint_2])

    # Remove one app endpoint.
    :ok = Resources.update_app_endpoints(res, "2", [@app_endpoint_1])
    assert_cds(pub, "2", [@app_endpoint_1])
    assert_rds(pub, "2", [@app_endpoint_1])
    assert_eds(pub, "2", [@app_endpoint_1])
  end
end
