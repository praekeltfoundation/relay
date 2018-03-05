defmodule Relay.CertsTest do
  use ExUnit.Case

  alias Relay.Certs

  @localhost_pem Path.expand("../support/localhost.pem", __DIR__)

  test "get a list of valid hostnames from a cert" do
    [_key, cert, _cacert] = :public_key.pem_decode(File.read!(@localhost_pem))
    hostnames = Certs.get_hostnames(cert)
    assert ["localhost", "pebble"] = Enum.sort(hostnames)
  end

  test "some certs may have no hostnames" do
    [_key, _cert, cacert] = :public_key.pem_decode(File.read!(@localhost_pem))
    assert [] = Certs.get_hostnames(cacert)
  end

  test "collect hostnames for all end-entity certs in pem data" do
    hostnames = Certs.get_end_entity_hostnames(File.read!(@localhost_pem))
    assert ["localhost", "pebble"] = Enum.sort(hostnames)
  end
end
