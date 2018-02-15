defmodule Relay.Demo2 do
  alias Relay.Store

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  defp call_async(func_name) do
    Task.async(fn ->
      :ok = GenServer.call(__MODULE__, func_name)
      receive do
        {:ok, resp} -> resp
      end
    end)
  end

  # Callbacks

  def init(_args) do
    call_async(:clusters)
    call_async(:listeners)
    call_async(:routes)
    call_async(:endpoints)
    {:ok, %{}}
  end

  def handle_call(:clusters, _from, state) do
    Store.update(Store, :cds, "1", Relay.Demo.clusters())
    {:reply, :ok, state}
  end

  def handle_call(:listeners, _from, state) do
    Store.update(Store, :lds, "1", Relay.Demo.listeners())
    {:reply, :ok, state}
  end

  def handle_call(:routes, _from, state) do
    Store.update(Store, :rds, "1", Relay.Demo.routes())
    {:reply, :ok, state}
  end

  def handle_call(:endpoints, _from, state) do
    Store.update(Store, :eds, "1", Relay.Demo.endpoints())
    {:reply, :ok, state}
  end
end
