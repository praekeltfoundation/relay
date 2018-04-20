defmodule Relay.Certs.FilesystemTest do
  use ExUnit.Case, async: false

  alias Relay.Certs.Filesystem
  alias Relay.{Certs, Resources}

  setup ctx do
    TestHelpers.override_log_level(:warn)
    TestHelpers.setup_apps([:cowboy, :httpoison])

    ctx = Map.put_new(ctx, :cert_dirs, ["certs"])
    {tmpdir, cert_paths} = TestHelpers.tmpdir_subdirs(ctx.cert_dirs)
    put_certs_config(paths: cert_paths)

    {:ok, res} = start_supervised({TestHelpers.StubGenServer, self()})

    %{tmpdir: tmpdir, cert_paths: cert_paths, res: res}
  end

  defp put_certs_config(opts) do
    certs_config = Application.fetch_env!(:relay, :certs) |> Keyword.merge(opts)
    TestHelpers.put_env(:relay, :certs, certs_config)
  end

  defp copy_cert(cert_file, cert_path) do
    src = TestHelpers.support_path(cert_file)
    dst = Path.join(cert_path, cert_file)
    File.cp!(src, dst)
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
    {:ok, _} = start_supervised({Filesystem, resources: res})
    assert_receive_update([])
  end

  test "startup sync one cert", %{cert_paths: [cert_path], res: res} do
    copy_cert("localhost.pem", cert_path)
    {:ok, _} = start_supervised({Filesystem, resources: res})
    assert_receive_update(["localhost.pem"])
  end

  test "update with new cert", %{cert_paths: [cert_path], res: res} do
    copy_cert("localhost.pem", cert_path)
    {:ok, cfs} = start_supervised({Filesystem, resources: res})
    assert_receive_update(["localhost.pem"])
    copy_cert("demo.pem", cert_path)
    GenServer.call(cfs, :update_state)
    assert_receive_update(["localhost.pem", "demo.pem"])
  end

  @tag cert_dirs: ["certs", "different"]
  test "configure cert paths", %{cert_paths: cert_paths} do
    assert Application.fetch_env!(:relay, :certs) |> Keyword.fetch!(:paths) == cert_paths
  end

  test "mlb signal update", %{cert_paths: [cert_path], res: res} do
    copy_cert("localhost.pem", cert_path)
    {:ok, _} = start_supervised({Filesystem, resources: res})
    assert_receive_update(["localhost.pem"])
    copy_cert("demo.pem", cert_path)
    assert_post("http://localhost:9090/_mlb_signal/hup", 204)
    assert_receive_update(["localhost.pem", "demo.pem"])
  end

  test "mlb bad http", %{res: res} do
    {:ok, _} = start_supervised({Filesystem, resources: res})
    assert_post("http://localhost:9090/_mlb_signal/term", 404)
    assert_post("http://localhost:9090/wordpress/wp-login.php", 404)
  end

  test "configure mlb port", %{cert_paths: [cert_path], res: res} do
    copy_cert("localhost.pem", cert_path)
    put_certs_config(mlb_port: 9091)
    {:ok, _} = start_supervised({Filesystem, resources: res})
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
