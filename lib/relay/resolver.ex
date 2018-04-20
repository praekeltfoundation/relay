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

  @spec start_link(term) :: Agent.on_start()
  def start_link(_), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @spec getaddr(String.t()) :: String.t()
  def getaddr(hostname) do
    if is_address?(hostname) do
      hostname
    else
      Agent.get_and_update(__MODULE__, fn cache ->
        case cache_get(cache, hostname) do
          nil ->
            {:ok, address} = getaddr_impl(hostname)
            {address, cache_put(cache, hostname, address)}

          address ->
            {address, cache}
        end
      end)
    end
  end

  @spec is_address?(String.t()) :: boolean
  defp is_address?(hostname_or_addr) do
    case hostname_or_addr |> to_charlist() |> :inet.parse_address() do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @spec getaddr_impl(String.t()) :: {:ok, String.t()} | {:error, :inet.posix()}
  defp getaddr_impl(hostname) do
    # FIXME: Support IPv6 DNS
    case hostname |> to_charlist() |> :inet.getaddr(:inet) do
      {:ok, addr} ->
        {:ok, addr |> :inet.ntoa() |> to_string()}

      {:error, err} ->
        Log.error("Error looking up hostname '#{hostname}': #{err}")
        {:error, err}
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
