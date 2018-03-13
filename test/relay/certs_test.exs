defmodule Relay.CertsTest do
  use ExUnit.Case

  alias Relay.Certs

  defp read_cert!(certfile) do
    Path.join("../support/", certfile)
    |> Path.expand(__DIR__)
    |> File.read!()
  end

  test "pem encode" do
    [key, cert, cacert] = :public_key.pem_decode(read_cert!("localhost.pem"))
    pem_data = :public_key.pem_encode([key, cert, cacert])
    assert ^pem_data = Certs.pem_encode(pem_data)
    assert ^pem_data = Certs.pem_encode([key, cert, cacert])
    pem_key = :public_key.pem_encode([key])
    assert ^pem_key = Certs.pem_encode(key)
  end

  test "get certs from pem data" do
    pem_data = read_cert!("localhost.pem")
    [_key, cert, cacert] = :public_key.pem_decode(pem_data)
    assert [^cert, ^cacert] = Certs.get_certs(pem_data)
  end

  test "get key from pem data" do
    pem_data = read_cert!("localhost.pem")
    [key, _cert, _cacert] = :public_key.pem_decode(pem_data)
    assert {:ok, ^key} = Certs.get_key(pem_data)
  end

  test "get key from pem data with no keys" do
    certs = Certs.get_certs(read_cert!("localhost.pem"))
    assert :error = Certs.get_key(certs)
  end

  test "get a list of valid hostnames from a cert" do
    [_key, cert, _cacert] = :public_key.pem_decode(read_cert!("localhost.pem"))
    hostnames = Certs.get_hostnames(cert)
    assert ["localhost", "pebble"] = Enum.sort(hostnames)
  end

  test "some certs may have no hostnames" do
    [_key, _cert, cacert] = :public_key.pem_decode(read_cert!("localhost.pem"))
    assert [] = Certs.get_hostnames(cacert)
  end

  test "collect hostnames for all end-entity certs in pem data" do
    hostnames = Certs.get_end_entity_hostnames(read_cert!("localhost.pem"))
    assert ["localhost", "pebble"] = Enum.sort(hostnames)
  end

  test "collect hostnames for self-signed cert without SAN" do
    hostnames = Certs.get_end_entity_hostnames(read_cert!("demo-nosan.pem"))
    assert ["demo-nosan.example.com"] = Enum.sort(hostnames)
  end

  test "collect hostnames for self-signed cert with SAN" do
    hostnames = Certs.get_end_entity_hostnames(read_cert!("demo.pem"))
    assert ["demo.example.com", "demo.example.net"] = Enum.sort(hostnames)
  end
end
