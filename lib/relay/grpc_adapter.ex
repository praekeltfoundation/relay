defmodule Relay.GRPCAdapter do
  @moduledoc """
  A wrapper around GRPC.Adapter.Cowboy for handling some startup edge cases
  more cleanly. This allows us to not worry about delays in the listening port
  being released after a crash or shutdown.

  This wrapper is only used by the supervisor, so we don't need the start and
  stop functions that GRPC.Server calls. Furthermore, we don't need any of the
  request or stream handling functions, because the request handler we get via
  the wrapped adapter is GRPC.Adapter.Cowboy.Handler and that references
  GRPC.Adapter.Cowboy directly. Thus, the only functions we need to wrap are
  start_link (to do the retries) and child_spec (to swap out the wrapped
  adapter's module for our wrapper in the supervisor spec).
  """

  # Retry interval in milliseconds
  @retry_interval 50

  # Retry timeout in milliseconds
  @retry_timeout 1_000

  alias GRPC.Adapter.Cowboy, as: GAC

  # Override start_link to add our own retry-with-timeout logic.
  @spec start_link(atom, GRPC.Server.servers_map(), [any]) :: {:ok, pid} | {:error, any}
  def start_link(scheme, servers, args) do
    start_fun = fn() -> GAC.start_link(scheme, servers, args) end
    retry_start(start_fun, now() + @retry_timeout)
  end

  @spec now() :: integer
  defp now(), do: System.monotonic_time(:milliseconds)

  @spec retry_start((() -> {:ok, pid} | {:error, any}), integer) :: {:ok, pid} | {:error, any}
  defp retry_start(start_fun, deadline) do
    result = start_fun.()
    if (now() + @retry_interval < deadline) and retry?(result) do
      Process.sleep(@retry_interval)
      retry_start(start_fun, deadline)
    else
      result
    end
  end

  @spec retry?({:ok, pid} | {:error, any}) :: boolean
  defp retry?({:error, {:shutdown, {:failed_to_start_child, _, reason}}}),
    do: retry?({:error, reason})
  defp retry?({:error, {:listen_error, _, :eaddrinuse}}), do: true
  defp retry?(_), do: false


  # Override child_spec to replace the adapter module with our own.
  @spec child_spec(GRPC.Server.servers_map(), non_neg_integer, Keyword.t()) :: Supervisor.Spec.spec()
  def child_spec(servers, port, opts) do
    {ref, {_module, func, args}, type, timeout, kind, modules} =
      GAC.child_spec(servers, port, opts)
    {ref, {__MODULE__, func, args}, type, timeout, kind, modules}
  end
end
