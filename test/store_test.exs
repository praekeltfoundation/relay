defmodule Relay.StoreTest.Macros do
  defmacro xds_tests(name_suffix, assertion) do
    Relay.Store.discovery_services()
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

  import Relay.StoreTest.Macros

  setup do
    {:ok, store} = start_supervised(Store)
    %{store: store}
  end

  def get_resources(store, xds) do
    {:ok, resources} = GenServer.call(store, {:_get_resources, xds})
    resources
  end

  xds_tests "subscribe idempotent", fn(store, xds) ->
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new()}
    assert Store.subscribe(store, xds, self()) == {:ok, "", []}
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new([self()])}
    assert Store.subscribe(store, xds, self()) == {:ok, "", []}
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new([self()])}
  end

  xds_tests "unsubscribe idempotent", fn(store, xds) ->
    assert Store.subscribe(store, xds, self()) == {:ok, "", []}
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new([self()])}
    assert Store.unsubscribe(store, xds, self()) == :ok
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new()}
    assert Store.unsubscribe(store, xds, self()) == :ok
    assert get_resources(store, xds) == %Resources{subscribers: MapSet.new()}
  end

  xds_tests "subscribers receive updates", fn(store, xds) ->
    assert Store.subscribe(store, xds, self()) == {:ok, "", []}

    resources = [:foo, :bar]
    assert Store.update(store, xds, "1", resources) == :ok

    assert_receive {^xds, "1", ^resources}, 1_000
  end

  xds_tests "old updates ignored", fn(store, xds) ->
    resources = [:foobar, :baz]
    assert Store.update(store, xds, "2", resources) == :ok

    assert Store.subscribe(store, xds, self()) == {:ok, "2", resources}

    old_resources = [:foo, :bar]
    assert Store.update(store, xds, "1", old_resources) == :ok

    # Assert the stored resources haven't changed
    assert %Resources{version_info: "2", resources: ^resources} = get_resources(store, xds)
    # Assert we don't receive any updates for this xds
    refute_received {^xds, _, _}
  end
end
