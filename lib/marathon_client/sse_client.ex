defmodule MarathonClient.SSEClient do
  @moduledoc """
  A GenServer to receive async responses from the HTTP client and forward the
  data chunks to the SSE parser.
  """

  use LogWrapper, as: Log

  use GenServer

  alias MarathonClient.SSEParser

  ## Client API

  @doc """
  Starts a new SSEClient.
  """
  def start_link({url, listeners, timeout}, opts \\ []) do
    GenServer.start_link(__MODULE__, {url, listeners, timeout}, opts)
  end

  ## Server callbacks

  def init({url, listeners, timeout}) do
    headers = %{"Accept" => "text/event-stream"}
    {:ok, ssep} = SSEParser.start_link([])
    Enum.each(listeners, fn l -> SSEParser.register_listener(ssep, l) end)
    r = HTTPoison.get!(
      url, headers, stream_to: self(), recv_timeout: timeout)
    # It's safe to receive in here, because the main GenServer receive loop
    # has not yet started.
    receive do
      %HTTPoison.AsyncStatus{code: 200} ->
        {:ok, {r, ssep}}
      msg ->
        Log.debug("Failed to connect to stream: #{inspect msg}")
        {:stop, "Error connecting to event stream: #{inspect msg}"}
    end
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, {_, ssep}=state) do
    SSEParser.feed_data(ssep, chunk)
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncHeaders{}, state) do
    # Ignore the headers. There's nothing we care about in them.
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncEnd{}, state) do
    {:stop, :normal, state}
  end

  def handle_info(%HTTPoison.Error{reason: reason}, state) do
    {:stop, reason, state}
  end

  def handle_info(msg, state) do
    Log.debug("Unexpected message: #{inspect msg}") # noqa
    {:noreply, state}
  end
end
