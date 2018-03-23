Code.require_file(Path.join([__DIR__, "resources", "resources_helper.exs"]))

defmodule Relay.ResourcesTest do
  use ExUnit.Case, async: true

  alias Relay.{Publisher, Resources}

  import LDSHelper, only: [listener_info: 1]

  @cert_info_1 %Resources.CertInfo{
    domains: ["example.com"],
    key: "PEM key for example.com",
    cert_chain: "PEM certs for example.com"
  }

  @cert_info_2 %Resources.CertInfo{
    domains: ["example.net", "www.example.net"],
    key: "PEM key for example.net",
    cert_chain: "PEM certs for example.net"
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

  test "does not push empty state at startup", %{pub: pub, res: res} do
    # The publisher has not received any listeners.
    assert get_pub_state(pub, :lds) == {"", []}
    # Send a no-op SNI cert update to trigger a push.
    :ok = Resources.update_sni_certs(res, "1", [])
    # The publisher has received HTTP and HTTPS listener with no certs.
    assert {"1", [http, https]} = get_pub_state(pub, :lds)
    assert listener_info(http) == {"http", 8080, [nil]}
    assert listener_info(https) == {"https", 8443, []}
  end

  test "pushes listeners with cert info in HTTP filter chains", %{pub: pub, res: res} do
    # Add two certs.
    :ok = Resources.update_sni_certs(res, "1", [@cert_info_1, @cert_info_2])
    assert {"1", [http, https]} = get_pub_state(pub, :lds)
    assert listener_info(http) == {"http", 8080, [nil]}
    assert listener_info(https) == {"https", 8443, [@cert_info_1, @cert_info_2]}

    # Remove one cert.
    :ok = Resources.update_sni_certs(res, "2", [@cert_info_1])
    assert {"2", [http, https]} = get_pub_state(pub, :lds)
    assert listener_info(http) == {"http", 8080, [nil]}
    assert listener_info(https) == {"https", 8443, [@cert_info_1]}
  end
end
