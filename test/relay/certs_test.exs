defmodule Relay.CertsTest do
  use ExUnit.Case

  alias Relay.Certs

  defp read_cert!(certfile), do: certfile |> TestHelpers.support_path() |> File.read!()

  test "pem encode" do
    [key, cert, cacert] = :public_key.pem_decode(read_cert!("localhost.pem"))
    pem_data = :public_key.pem_encode([key, cert, cacert])
    assert Certs.pem_encode(pem_data) == pem_data
    assert Certs.pem_encode([key, cert, cacert]) == pem_data
    assert Certs.pem_encode(key) == :public_key.pem_encode([key])
  end

  test "get certs from pem data" do
    pem_data = read_cert!("localhost.pem")
    [_key, cert, cacert] = :public_key.pem_decode(pem_data)
    assert Certs.get_certs(pem_data) == [cert, cacert]
  end

  test "get key from pem data" do
    pem_data = read_cert!("localhost.pem")
    [key, _cert, _cacert] = :public_key.pem_decode(pem_data)
    assert Certs.get_key(pem_data) == {:ok, key}
  end

  test "get key from pem data with no keys" do
    certs = Certs.get_certs(read_cert!("localhost.pem"))
    assert Certs.get_key(certs) == :error
  end

  test "get a list of valid hostnames from a cert" do
    [_key, cert, _cacert] = :public_key.pem_decode(read_cert!("localhost.pem"))
    hostnames = Certs.get_hostnames(cert)
    assert Enum.sort(hostnames) == ["localhost", "pebble"]
  end

  test "some certs may have no hostnames" do
    [_key, _cert, cacert] = :public_key.pem_decode(read_cert!("localhost.pem"))
    assert Certs.get_hostnames(cacert) == []
  end

  test "collect hostnames for all end-entity certs in pem data" do
    hostnames = Certs.get_end_entity_hostnames(read_cert!("localhost.pem"))
    assert Enum.sort(hostnames) == ["localhost", "pebble"]
  end

  test "collect hostnames for self-signed cert without SAN" do
    hostnames = Certs.get_end_entity_hostnames(read_cert!("demo-nosan.pem"))
    assert Enum.sort(hostnames) == ["demo-nosan.example.com"]
  end

  test "collect hostnames for self-signed cert with SAN" do
    hostnames = Certs.get_end_entity_hostnames(read_cert!("demo.pem"))
    assert Enum.sort(hostnames) == ["demo.example.com", "demo.example.net"]
  end

  test ":relay_pk_utils.get_end_entity_certs filters out non-certs" do
    # This code path is never exercised through Relay.Certs, so we have to test
    # it directly.
    [key, cert, cacert] = :public_key.pem_decode(read_cert!("localhost.pem"))
    assert :relay_pk_utils.get_end_entity_certs([key, cert, cacert]) == [cert]
  end
end
