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

  # Retry timeout in milliseconds
  @retry_timeout 1_000

  alias GRPC.Adapter.Cowboy, as: GAC
  alias Relay.RetryStart

  # Override start_link to add our own retry-with-timeout logic.
  @spec start_link(atom, GRPC.Server.servers_map(), [any]) :: {:ok, pid} | {:error, any}
  def start_link(scheme, servers, args) do
    start_fun = fn -> GAC.start_link(scheme, servers, args) end
    RetryStart.retry_start(start_fun, @retry_timeout)
  end

  # Override child_spec to replace the adapter module with our own.
  @spec child_spec(GRPC.Server.servers_map(), non_neg_integer, Keyword.t()) ::
          Supervisor.Spec.spec()
  def child_spec(servers, port, opts) do
    {ref, {_module, func, args}, type, timeout, kind, modules} =
      GAC.child_spec(servers, port, opts)

    {ref, {__MODULE__, func, args}, type, timeout, kind, modules}
  end
end
