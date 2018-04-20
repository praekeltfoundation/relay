defmodule Relay.ResolverTest do
  use ExUnit.Case, async: false

  alias Relay.Resolver

  setup do
    {:ok, resolver} = start_supervised(Resolver)

    %{resolver: resolver}
  end

  defp get_cache(resolver), do: Agent.get(resolver, &(&1))

  test "ipv4 address", %{resolver: resolver} do
    assert Resolver.getaddr(resolver, "127.0.0.1") == "127.0.0.1"
  end

  test "ipv6 address", %{resolver: resolver} do
    assert Resolver.getaddr(resolver, "::1") == "::1"
  end

  test "hostname lookup", %{resolver: resolver} do
    assert Resolver.getaddr(resolver, "10.0.0.1.xip.io") == "10.0.0.1"
  end

  test "addresses not cached", %{resolver: resolver} do
    assert Resolver.getaddr(resolver, "172.17.0.1") == "172.17.0.1"

    assert get_cache(resolver) == %{}
  end

  test "lookups cached", %{resolver: resolver} do
    assert Resolver.getaddr(resolver, "10.0.0.2.xip.io") == "10.0.0.2"

    assert %{"10.0.0.2.xip.io" => {"10.0.0.2", expiry1}} = get_cache(resolver)
    assert expiry1 > System.monotonic_time(:milliseconds)

    # Lookup again... should hit the cache and have the same expiry
    assert Resolver.getaddr(resolver, "10.0.0.2.xip.io") == "10.0.0.2"
    assert %{"10.0.0.2.xip.io" => {"10.0.0.2", expiry2}} = get_cache(resolver)
    assert expiry2 == expiry1
  end

  test "lookup cache expires", %{resolver: resolver} do
    TestHelpers.put_env(:relay, :resolver, ttl: 10)

    assert Resolver.getaddr(resolver, "10.0.0.3.xip.io") == "10.0.0.3"
    assert %{"10.0.0.3.xip.io" => {"10.0.0.3", expiry1}} = get_cache(resolver)

    # Wait until the cache entry has expired
    Process.sleep(50)

    # Lookup again... should miss the cache and have a new expiry
    assert Resolver.getaddr(resolver, "10.0.0.3.xip.io") == "10.0.0.3"
    assert %{"10.0.0.3.xip.io" => {"10.0.0.3", expiry2}} = get_cache(resolver)
    assert expiry2 > expiry1
  end
end
