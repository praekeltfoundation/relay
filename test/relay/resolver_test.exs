defmodule Relay.ResolverTest do
  use ExUnit.Case, async: false

  alias Relay.Resolver

  setup do
    TestHelpers.override_log_level(:info)

    {:ok, resolver} = start_supervised(Resolver)

    %{resolver: resolver}
  end

  defp get_cache(), do: Agent.get(Resolver, & &1)

  test "ipv4 address" do
    assert Resolver.getaddr("127.0.0.1") == "127.0.0.1"
  end

  test "ipv6 address" do
    assert Resolver.getaddr("::1") == "::1"
  end

  test "hostname lookup" do
    assert Resolver.getaddr("localhost") == "127.0.0.1"
  end

  test "hostname lookup not in /etc/hosts" do
    assert Resolver.getaddr("10.0.0.1.xip.io") == "10.0.0.1"
  end

  test "unknown hostname" do
    import ExUnit.CaptureLog

    assert capture_log(fn ->
             assert {{{:badmatch, {:error, :nxdomain}}, _}, _} =
                      catch_exit(Resolver.getaddr("notexist.localdomain"))
           end) =~ ~r"Error looking up hostname 'notexist\.localdomain'"
  end

  test "addresses not cached" do
    assert Resolver.getaddr("172.17.0.1") == "172.17.0.1"

    assert get_cache() == %{}
  end

  test "lookups cached" do
    assert Resolver.getaddr("localhost") == "127.0.0.1"

    assert %{"localhost" => {"127.0.0.1", expiry1}} = get_cache()
    assert expiry1 > System.monotonic_time(:milliseconds)

    # Lookup again... should hit the cache and have the same expiry
    assert Resolver.getaddr("localhost") == "127.0.0.1"
    assert %{"localhost" => {"127.0.0.1", expiry2}} = get_cache()
    assert expiry2 == expiry1
  end

  test "lookup cache expires" do
    TestHelpers.put_env(:relay, :resolver, ttl: 10)

    assert Resolver.getaddr("localhost") == "127.0.0.1"
    assert %{"localhost" => {"127.0.0.1", expiry1}} = get_cache()

    # Wait until the cache entry has expired
    Process.sleep(50)

    # Lookup again... should miss the cache and have a new expiry
    assert Resolver.getaddr("localhost") == "127.0.0.1"
    assert %{"localhost" => {"127.0.0.1", expiry2}} = get_cache()
    assert expiry2 > expiry1
  end
end
