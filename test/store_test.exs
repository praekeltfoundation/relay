defmodule Relay.StoreTest.Macros do
  defmacro xds_tests(name_suffix, assertion) do
    [:lds, :rds, :cds, :eds]
    |> Enum.map(fn(xds) ->
      quote do
        test "#{unquote(xds)} #{unquote(name_suffix)}", %{store: store},
          do: unquote(assertion).(store, unquote(xds))
      end
    end)
  end
end

defmodule Relay.StoreTest do
  use ExUnit.Case, async: true

  alias Relay.Store
  alias Store.Resources
  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment, Listener, RouteConfiguration}

  import Relay.StoreTest.Macros

  setup do
    {:ok, store} = start_supervised(Store)
    %{store: store}
  end

  def get_resources(store, xds) do
    {:ok, resources} = GenServer.call(store, {:_get_resources, xds})
    resources
  end

  defp subscribe(store, xds, pid), do:
    apply(Store, :"subscribe_#{xds}", [store, pid])

  defp unsubscribe(store, xds, pid), do:
    apply(Store, :"unsubscribe_#{xds}", [store, pid])

  defp update(store, xds, version_info, resources), do:
    apply(Store, :"update_#{xds}", [store, version_info, resources])

  xds_tests "subscribe idempotent", fn(store, xds) ->
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new()}
    assert subscribe(store, xds, self()) == {:ok, "", []}
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new([self()])}
    assert subscribe(store, xds, self()) == {:ok, "", []}
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new([self()])}
  end

  xds_tests "unsubscribe idempotent", fn(store, xds) ->
    assert subscribe(store, xds, self()) == {:ok, "", []}
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new([self()])}
    assert unsubscribe(store, xds, self()) == :ok
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new()}
    assert unsubscribe(store, xds, self()) == :ok
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new()}
  end

  xds_tests "subscribers receive updates", fn(store, xds) ->
    assert subscribe(store, xds, self()) == {:ok, "", []}

    resources = [:foo, :bar]
    assert update(store, xds, "1", resources) == :ok

    assert_receive {^xds, "1", ^resources}, 1_000
  end

  xds_tests "old updates ignored", fn(store, xds) ->
    resources = [:foobar, :baz]
    assert update(store, xds, "2", resources) == :ok

    assert subscribe(store, xds, self()) == {:ok, "2", resources}

    old_resources = [:foo, :bar]
    assert update(store, xds, "1", old_resources) == :ok

    # Assert the stored resources haven't changed
    assert %Resources{version_info: "2", resources: ^resources} = get_resources(store, xds)
    # Assert we don't receive any updates for this xds
    refute_received {^xds, _, _}
  end
end
