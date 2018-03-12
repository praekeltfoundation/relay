defmodule Relay.CertsTest do
  use ExUnit.Case

  alias Relay.Certs

  defp read_cert!(certfile) do
    Path.join("../support/", certfile)
    |> Path.expand(__DIR__)
    |> File.read!()
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
