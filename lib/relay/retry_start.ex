defmodule Relay.RetryStart do
  @moduledoc """
  Logic for retrying a server startup that can fail because the address it
  binds to is in use.
  """

  # Retry interval in milliseconds
  @retry_interval 50

  @spec now() :: integer
  defp now, do: System.monotonic_time(:milliseconds)

  @spec retry_start((() -> {:ok, pid} | {:error, any}), integer) :: {:ok, pid} | {:error, any}
  def retry_start(start_fun, timeout) do
    do_retry_start(start_fun, now() + timeout)
  end

  @spec do_retry_start((() -> {:ok, pid} | {:error, any}), integer) :: {:ok, pid} | {:error, any}
  defp do_retry_start(start_fun, deadline) do
    result = start_fun.()

    if now() + @retry_interval < deadline and retry?(result) do
      Process.sleep(@retry_interval)
      do_retry_start(start_fun, deadline)
    else
      result
    end
  end

  @spec retry?({:ok, pid} | {:error, any}) :: boolean
  defp retry?({:error, {:shutdown, {:failed_to_start_child, _, reason}}}),
    do: retry?({:error, reason})

  defp retry?({:error, {:listen_error, _, :eaddrinuse}}), do: true
  defp retry?(_), do: false
end
