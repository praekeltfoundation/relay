defmodule Relay.ResolverTest do
  use ExUnit.Case, async: false

  alias Relay.Resolver

  setup do
    {:ok, resolver} = start_supervised(Resolver)

    %{resolver: resolver}
  end

  defp get_cache(), do: Agent.get(Resolver, & &1)

  test "ipv4 address" do
    assert Resolver.getaddr("127.0.0.1") == {:ok, "127.0.0.1"}
  end

  test "ipv6 address" do
    assert Resolver.getaddr("::1") == {:ok, "::1"}
  end

  test "hostname lookup" do
    assert Resolver.getaddr("localhost") == {:ok, "127.0.0.1"}
  end

  test "hostname lookup not in /etc/hosts" do
    assert Resolver.getaddr("10.0.0.1.xip.io") == {:ok, "10.0.0.1"}
  end

  test "unknown hostname" do
    assert Resolver.getaddr("notexist.localdomain") == {:error, :nxdomain}
  end

  test "addresses not cached" do
    assert Resolver.getaddr("172.17.0.1") == {:ok, "172.17.0.1"}

    assert get_cache() == %{}
  end

  test "lookups cached" do
    assert Resolver.getaddr("localhost") == {:ok, "127.0.0.1"}

    assert %{"localhost" => {"127.0.0.1", expiry1}} = get_cache()
    assert expiry1 > System.monotonic_time(:milliseconds)

    # Lookup again... should hit the cache and have the same expiry
    assert Resolver.getaddr("localhost") == {:ok, "127.0.0.1"}
    assert %{"localhost" => {"127.0.0.1", expiry2}} = get_cache()
    assert expiry2 == expiry1
  end

  test "lookup cache expires" do
    TestHelpers.put_env(:relay, :resolver, ttl: 10)

    assert Resolver.getaddr("localhost") == {:ok, "127.0.0.1"}
    assert %{"localhost" => {"127.0.0.1", expiry1}} = get_cache()

    # Wait until the cache entry has expired
    Process.sleep(50)

    # Lookup again... should miss the cache and have a new expiry
    assert Resolver.getaddr("localhost") == {:ok, "127.0.0.1"}
    assert %{"localhost" => {"127.0.0.1", expiry2}} = get_cache()
    assert expiry2 > expiry1
  end
end
