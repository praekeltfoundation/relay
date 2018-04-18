defmodule Relay.ResolverTest do
  use ExUnit.Case, async: true

  alias Relay.Resolver

  setup do
    {:ok, resolver} = start_supervised(Resolver)

    %{resolver: resolver}
  end

  test "ipv4 address", %{resolver: resolver} do
    assert Resolver.getaddr(resolver, "127.0.0.1") == "127.0.0.1"
  end

  test "ipv6 address", %{resolver: resolver} do
    assert Resolver.getaddr(resolver, "::1") == "::1"
  end

  test "hostname lookup", %{resolver: resolver} do
    assert Resolver.getaddr(resolver, "10.0.0.1.xip.io") == "10.0.0.1"
  end
end
