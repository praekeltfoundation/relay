defmodule Relay.Resolver do
  @moduledoc """
  A very very simple DNS resolver. Uses `:inet.getaddr/2` which does get results
  from /etc/hosts but does not retrieve DNS TTLs. We also only fetch IPv4
  addresses currently.

  The world's simplest cache is implemented. It is unbounded and entries are
  never removed. All entries have a fixed TTL adjusted via the
  `relay.resolver.ttl` setting. Expired cache entries are ignored and then
  (hopefully) replaced.
  """

  use Agent

  use LogWrapper, as: Log

  # hostname => {address, expiry}
  @typep cache :: %{optional(String.t()) => {String.t(), integer}}
  @typep getaddr_result :: {:ok, String.t()} | {:error, :inet.posix()}

  @spec start_link(term) :: Agent.on_start()
  def start_link(_), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @spec getaddr(String.t()) :: getaddr_result
  def getaddr(hostname), do: getaddr(__MODULE__, hostname)

  @spec getaddr(Agent.agent(), String.t()) :: getaddr_result
  def getaddr(agent, hostname) do
    if is_address?(hostname) do
      {:ok, hostname}
    else
      Agent.get_and_update(agent, &getaddr_impl(&1, hostname))
    end
  end

  @spec is_address?(String.t()) :: boolean
  defp is_address?(hostname_or_addr) do
    case hostname_or_addr |> to_charlist() |> :inet.parse_address() do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @spec getaddr_impl(cache, String.t()) :: {getaddr_result, cache}
  defp getaddr_impl(cache, hostname) do
    case cache_get(cache, hostname) do
      nil ->
        # FIXME: Support IPv6 DNS
        case inet_getaddr(hostname, :inet) do
          {:ok, address} -> {{:ok, address}, cache_put(cache, hostname, address)}
          {:error, _} = error -> {error, cache}
        end

      address ->
        {{:ok, address}, cache}
    end
  end

  # A wrapper around `:inet.getaddr/2` that takes and returns Strings.
  @spec inet_getaddr(String.t(), :inet.address_family()) :: getaddr_result
  defp inet_getaddr(hostname, family) do
    case hostname |> to_charlist() |> :inet.getaddr(family) do
      {:ok, addr} -> {:ok, addr |> :inet.ntoa() |> to_string()}
      {:error, _} = error -> error
    end
  end

  @spec cache_get(cache, String.t()) :: String.t() | nil
  defp cache_get(cache, hostname) do
    case Map.get(cache, hostname) do
      {address, expiry} ->
        if System.monotonic_time(:milliseconds) < expiry do
          Log.debug("DNS cache hit: #{hostname} -> #{address}")
          address
        else
          Log.debug("DNS cache expired: #{hostname} -> #{address}")
          nil
        end

      nil ->
        Log.debug("DNS cache miss: #{hostname}")
        nil
    end
  end

  @spec cache_put(cache, String.t(), String.t()) :: cache
  defp cache_put(cache, hostname, address),
    do: Map.put(cache, hostname, {address, System.monotonic_time(:milliseconds) + ttl()})

  @spec ttl() :: non_neg_integer
  defp ttl(), do: Application.fetch_env!(:relay, :resolver) |> Keyword.fetch!(:ttl)
end
