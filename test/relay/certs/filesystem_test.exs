defmodule Relay.Certs.FilesystemTest do
  use ExUnit.Case, async: false

  alias Relay.Certs.Filesystem
  alias Relay.{Certs, Resources}

  defmodule StubGenServer do
    use GenServer

    def start_link(pid), do: GenServer.start_link(__MODULE__, pid, name: StubGenServer)

    @impl GenServer
    def init(pid), do: {:ok, pid}

    @impl GenServer
    def handle_call(msg, _from, pid) do
      send(pid, msg)
      {:reply, :ok, pid}
    end
  end

  setup ctx do
    TestHelpers.override_log_level(:warn)
    TestHelpers.setup_apps([:cowboy, :httpoison])

    ctx = Map.put_new(ctx, :cert_dirs, ["certs"])
    {tmpdir, cert_paths} = TestHelpers.tmpdir_subdirs(ctx.cert_dirs)

    certs_config =
      Application.fetch_env!(:relay, :certs)
      |> Keyword.put(:paths, cert_paths)

    TestHelpers.put_env(:relay, :certs, certs_config)

    {:ok, res} = start_supervised({StubGenServer, self()})

    %{tmpdir: tmpdir, cert_paths: cert_paths, res: res}
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

  defp assert_post(uri, code) do
    assert {:ok, %HTTPoison.Response{status_code: ^code, body: ""}} = HTTPoison.post(uri, "")
  end
end
