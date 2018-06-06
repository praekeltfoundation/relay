Code.require_file(Path.join([__DIR__, "..", "..", "vault_client", "vault_client_helper.exs"]))

defmodule Relay.Certs.VaultKVTest do
  use ExUnit.Case, async: false

  alias Relay.Certs.VaultKV
  alias Relay.{Certs, Resources}

  setup do
    TestHelpers.override_log_level(:warn)
    TestHelpers.setup_apps([:cowboy, :httpoison])

    {:ok, fv} = start_supervised(FakeVault)
    base_url = FakeVault.base_url(fv)
    token = FakeVault.auth_token(fv)
    FakeVault.set_kv_data(fv, "/marathon-acme/live", %{})

    put_certs_config(vault: [address: base_url, token: token, base_path: "/marathon-acme"])

    {:ok, res} = start_supervised({TestHelpers.StubGenServer, self()})

    %{res: res, fv: fv}
  end

  defp put_certs_config(opts) do
    certs_config = Application.fetch_env!(:relay, :certs) |> Keyword.merge(opts, &merge_cfg/3)
    TestHelpers.put_env(:relay, :certs, certs_config)
  end

  defp merge_cfg(:vault, old, new), do: Keyword.merge(old, new)
  defp merge_cfg(_key, _old, new), do: new

  defp store_cert(fv, cert_file, cert_name) do
    path = "/marathon-acme/certificates/#{cert_name}"
    FakeVault.set_kv_data(fv, path, cert_info_from_file(cert_file))
    live_path = "/marathon-acme/live"
    live = FakeVault.get_kv_data(fv, live_path)
    FakeVault.set_kv_data(fv, live_path, Map.put(live, cert_name, ""))
  end

  defp cert_info_from_file(cert_file) do
    cert_bundle = cert_file |> TestHelpers.support_path() |> File.read!()

    %Resources.CertInfo{
      domains: cert_bundle |> Certs.get_end_entity_hostnames(),
      key: cert_bundle |> Certs.get_key() |> get_ok() |> Certs.pem_encode(),
      cert_chain: cert_bundle |> Certs.get_certs() |> Certs.pem_encode()
    }
  end

  defp get_ok(thing) do
    assert {:ok, got} = thing
    got
  end

  defp assert_receive_update(cert_files) do
    expected_sni_certs = Enum.map(cert_files, &cert_info_from_file/1)
    assert_receive {:update_sni_certs, _version, sni_certs}, 100
    assert Enum.sort(sni_certs) == Enum.sort(expected_sni_certs)
  end

  test "startup sync no certs", %{res: res} do
    {:ok, _} = start_supervised({VaultKV, resources: res})
    assert_receive_update([])
  end

  test "startup sync one cert", %{fv: fv, res: res} do
    store_cert(fv, "localhost.pem", "localhost")
    {:ok, _} = start_supervised({VaultKV, resources: res})
    assert_receive_update(["localhost.pem"])
  end

  test "update with new cert", %{fv: fv, res: res} do
    store_cert(fv, "localhost.pem", "localhost")
    {:ok, cfs} = start_supervised({VaultKV, resources: res})
    assert_receive_update(["localhost.pem"])
    store_cert(fv, "demo.pem", "demo")
    GenServer.call(cfs, :update_state)
    assert_receive_update(["localhost.pem", "demo.pem"])
  end

  test "mlb signal update", %{fv: fv, res: res} do
    store_cert(fv, "localhost.pem", "localhost")
    {:ok, _} = start_supervised({VaultKV, resources: res})
    assert_receive_update(["localhost.pem"])
    store_cert(fv, "demo.pem", "demo")
    assert_post("http://localhost:9090/_mlb_signal/hup", 204)
    assert_receive_update(["localhost.pem", "demo.pem"])
  end

  test "mlb listener restart", %{fv: fv, res: res} do
    store_cert(fv, "localhost.pem", "localhost")
    {:ok, vkv} = start_supervised({VaultKV, resources: res})
    assert_receive_update(["localhost.pem"])
    # A kill signal means the terminate function isn't called.
    Process.exit(vkv, :kill)
    assert_receive_update(["localhost.pem"])
    store_cert(fv, "demo.pem", "demo")
    assert_post("http://localhost:9090/_mlb_signal/hup", 204)
    assert_receive_update(["localhost.pem", "demo.pem"])
  end

  test "mlb bad http", %{res: res} do
    {:ok, _} = start_supervised({VaultKV, resources: res})
    assert_post("http://localhost:9090/_mlb_signal/term", 404)
    assert_post("http://localhost:9090/wordpress/wp-login.php", 404)
  end

  test "configure mlb port", %{fv: fv, res: res} do
    store_cert(fv, "localhost.pem", "localhost")
    put_certs_config(mlb_port: 9091)
    {:ok, _} = start_supervised({VaultKV, resources: res})
    assert_receive_update(["localhost.pem"])

    assert_no_post("http://localhost:9090/_mlb_signal/hup", :econnrefused)
    refute_receive {:update_sni_certs, _, _}, 100

    assert_post("http://localhost:9091/_mlb_signal/hup", 204)
    assert_receive_update(["localhost.pem"])
  end

  defp assert_post(uri, code) do
    assert {:ok, %HTTPoison.Response{status_code: ^code, body: ""}} = HTTPoison.post(uri, "")
  end

  defp assert_no_post(uri, reason) do
    assert {:error, %HTTPoison.Error{reason: ^reason}} = HTTPoison.post(uri, "")
  end
end
