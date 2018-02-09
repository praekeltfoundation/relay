defmodule Relay.Demo2 do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def clusters(), do: call_and_wait(:clusters)
  def listeners(), do: call_and_wait(:listeners)

  defp call_and_wait(func_name) do
    t = Task.async(fn ->
      :ok = GenServer.call(__MODULE__, func_name)
      receive do
        {:ok, resp} -> resp
      end
    end)
    Task.await(t)
  end

  # Callbacks

  def init(_args) do
    {:ok, %{}}
  end

  def handle_call(:clusters, {pid, _ref}, state) do
    Process.send_after(self(), {:clusters, pid}, 1000)
    {:reply, :ok, state}
  end

  def handle_call(:listeners, {pid, _ref}, state) do
    Process.send_after(self(), {:listeners, pid}, 2000)
    {:reply, :ok, state}
  end

  def handle_info({name, pid}, state) do
    send(pid, {:ok, apply(Relay.Demo, name, [])})
    {:noreply, state}
  end
end
