defmodule Relay.GRPCAdapter do
  @moduledoc """
  A wrapper around GRPC.Adapter.Cowboy for handling some startup edge cases
  more cleanly. This allows us to not worry about delays in the listening port
  being released after a crash or shutdown.
  """

  # Retry interval in milliseconds
  @retry_interval 50

  # Retry timeout in milliseconds
  @retry_timeout 1_000

  alias GRPC.Adapter.Cowboy, as: GAC

  # We override start_link to do add our own retry-with-timeout logic.
  @spec start_link(atom, GRPC.Server.servers_map(), [any]) :: {:ok, pid} | {:error, any}
  def start_link(scheme, servers, args) do
    start_fun = fn() -> GAC.start_link(scheme, servers, args) end
    retry_start(start_fun, now() + @retry_timeout)
  end

  defp now(), do: System.monotonic_time(:milliseconds)

  defp retry_start(start_fun, deadline) do
    result = start_fun.()
    if (now() + @retry_interval < deadline) and retry?(result) do
      Process.sleep(@retry_interval)
      retry_start(start_fun, deadline)
    else
      result
    end
  end

  # defp retry?({:error, {:shutdown, {_, _, {{_, {:error, :eaddrinuse}}, _}}}}),
  #   do: true
  defp retry?({:error, {:shutdown, {:failed_to_start_child, _, reason}}}),
    do: retry?({:error, reason})
  defp retry?({:error, {:listen_error, _, :eaddrinuse}}), do: true
  defp retry?(_), do: false


  # We override child_spec to replace the adapter module with our own.
  @spec child_spec(GRPC.Server.servers_map(), non_neg_integer, Keyword.t()) :: Supervisor.Spec.spec()
  def child_spec(servers, port, opts) do
    {ref, {_module, func, args}, type, timeout, kind, modules} =
      GAC.child_spec(servers, port, opts)
    {ref, {__MODULE__, func, args}, type, timeout, kind, modules}
  end

  # All other functions are just forwarded to the wrapped adapter. Some of the
  # typespecs are slightly modified to make dialyzer happy.

  @spec start(GRPC.Server.servers_map(), non_neg_integer, keyword) :: {:ok, pid, char}
  def start(servers, port, opts), do: GAC.start(servers, port, opts)

  @spec stop(GRPC.Server.servers_map()) :: :ok | {:error, :not_found}
  def stop(servers), do: GAC.stop(servers)

  @spec read_body(GRPC.Client.Stream.t()) :: {:ok, binary, GRPC.Client.Stream.t()}
  def read_body(stream), do: GAC.read_body(stream)

  @spec reading_stream(GRPC.Client.Stream.t(), ([binary] -> [struct])) :: Enumerable.t()
  def reading_stream(stream, func), do: GAC.reading_stream(stream, func)

  @spec stream_send(GRPC.Server.Stream.t(), binary) :: any
  def stream_send(stream, data), do: GAC.stream_send(stream, data)

  @doc false
  @spec flow_control(GRPC.Client.Stream.t(), non_neg_integer) :: any
  def flow_control(stream, size), do: flow_control(stream, size)
end
