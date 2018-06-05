Code.require_file(Path.join([__DIR__, "vault_client", "vault_client_helper.exs"]))

defmodule VaultClientTest do
  use ExUnit.Case

  setup_all do
    TestHelpers.override_log_level(:info)
    TestHelpers.setup_apps([:cowboy, :hackney])
  end

  describe "vault kv" do
    test "read" do
      {:ok, fv} = start_supervised(FakeVault)

      cfg = %VaultClient.ClientConfig{
        base_url: FakeVault.base_url(fv),
        token: FakeVault.auth_token(fv)
      }

      FakeVault.set_kv_data(fv, "/blah", %{"a" => 1, "b" => "two"})

      resp = VaultClient.read_kv(cfg, "/blah")
      assert {:ok, %{"data" => %{"data" => data, "metadata" => _}}} = resp
      assert data == %{"a" => 1, "b" => "two"}
    end

    test "read data" do
      {:ok, fv} = start_supervised(FakeVault)

      cfg = %VaultClient.ClientConfig{
        base_url: FakeVault.base_url(fv),
        token: FakeVault.auth_token(fv)
      }

      FakeVault.set_kv_data(fv, "/blah", %{"a" => 1, "b" => "two"})

      resp = VaultClient.read_kv_data(cfg, "/blah")
      assert resp == {:ok, %{"a" => 1, "b" => "two"}}
    end

    test "read missing" do
      {:ok, fv} = start_supervised(FakeVault)

      cfg = %VaultClient.ClientConfig{
        base_url: FakeVault.base_url(fv),
        token: FakeVault.auth_token(fv)
      }

      resp = VaultClient.read_kv(cfg, "/missing")
      assert resp == {:error, {404, %{"errors" => []}}}
    end

    test "read missing data" do
      {:ok, fv} = start_supervised(FakeVault)

      cfg = %VaultClient.ClientConfig{
        base_url: FakeVault.base_url(fv),
        token: FakeVault.auth_token(fv)
      }

      resp = VaultClient.read_kv_data(cfg, "/missing")
      assert resp == {:error, {404, %{"errors" => []}}}
    end

    test "bad auth" do
      {:ok, fv} = start_supervised(FakeVault)

      cfg = %VaultClient.ClientConfig{
        base_url: FakeVault.base_url(fv),
        token: "bad-token"
      }

      resp = VaultClient.read_kv(cfg, "/treason")
      assert resp == {:error, {403, %{"errors" => ["permission denied"]}}}
    end
  end
end
