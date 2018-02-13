defmodule Relay.StoreTest do
  use ExUnit.Case, async: true

  alias Relay.Store
  alias Store.Resources
  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment, Listener, RouteConfiguration}

  setup do
    {:ok, store} = start_supervised(Store)
    %{store: store}
  end

  def get_resources(store, xds) do
    {:ok, resources} = GenServer.call(store, {:_get_resources, xds})
    resources
  end

  # TODO: break out these tests into smaller tests
  test "lds basics", %{store: store} do
    # We can store something
    resources = [Listener.new(name: "test")]
    assert Store.update_lds(store, "1", resources) == :ok

    # When we subscribe we receive the existing state
    assert Store.subscribe_lds(store, self()) == {:ok, "1", resources}

    # We can update again
    resources2 = [Listener.new(name: "test2")]
    assert Store.update_lds(store, "2", resources2) == :ok

    # ...and we receive the notification
    assert_receive {:lds, "2", ^resources2}, 1_000

    # ...if we try update with older resources
    assert Store.update_lds(store, "1", resources) == :ok
    # we receive no message and the state is unchanged
    assert %Resources{version_info: "2", resources: ^resources2} = get_resources(store, :lds)

    # We can unsubscribe
    assert Store.unsubscribe_lds(store, self()) == :ok

    # ...and we're no longer subscribed
    %Resources{subscribers: subscribers} = get_resources(store, :lds)
    assert subscribers == MapSet.new()
  end

  test "rds basics", %{store: store} do
    # We can store something
    resources = [RouteConfiguration.new(name: "test")]
    assert Store.update_rds(store, "1", resources) == :ok

    # When we subscribe we receive the existing state
    assert Store.subscribe_rds(store, self()) == {:ok, "1", resources}

    # We can update again
    resources2 = [RouteConfiguration.new(name: "test2")]
    assert Store.update_rds(store, "2", resources2) == :ok

    # ...and we receive the notification
    assert_receive {:rds, "2", ^resources2}, 1_000

    # ...if we try update with older resources
    assert Store.update_rds(store, "1", resources) == :ok
    # we receive no message and the state is unchanged
    assert %Resources{version_info: "2", resources: ^resources2} = get_resources(store, :rds)

    # We can unsubscribe
    assert Store.unsubscribe_rds(store, self()) == :ok

    # ...and we're no longer subscribed
    %Resources{subscribers: subscribers} = get_resources(store, :rds)
    assert subscribers == MapSet.new()
  end

  test "cds basics", %{store: store} do
    # We can store something
    resources = [Cluster.new(name: "test")]
    assert Store.update_cds(store, "1", resources) == :ok

    # When we subscribe we receive the existing state
    assert Store.subscribe_cds(store, self()) == {:ok, "1", resources}

    # We can update again
    resources2 = [Cluster.new(name: "test2")]
    assert Store.update_cds(store, "2", resources2) == :ok

    # ...and we receive the notification
    assert_receive {:cds, "2", ^resources2}, 1_000

    # ...if we try update with older resources
    assert Store.update_cds(store, "1", resources) == :ok
    # we receive no message and the state is unchanged
    assert %Resources{version_info: "2", resources: ^resources2} = get_resources(store, :cds)

    # We can unsubscribe
    assert Store.unsubscribe_cds(store, self()) == :ok

    # ...and we're no longer subscribed
    %Resources{subscribers: subscribers} = get_resources(store, :cds)
    assert subscribers == MapSet.new()
  end

  test "eds basics", %{store: store} do
    # We can store something
    resources = [ClusterLoadAssignment.new(name: "test")]
    assert Store.update_eds(store, "1", resources) == :ok

    # When we subscribe we receive the existing state
    assert Store.subscribe_eds(store, self()) == {:ok, "1", resources}

    # We can update again
    resources2 = [ClusterLoadAssignment.new(name: "test2")]
    assert Store.update_eds(store, "2", resources2) == :ok

    # ...and we receive the notification
    assert_receive {:eds, "2", ^resources2}, 1_000

    # ...if we try update with older resources
    assert Store.update_eds(store, "1", resources) == :ok
    # we receive no message and the state is unchanged
    assert %Resources{version_info: "2", resources: ^resources2} = get_resources(store, :eds)

    # We can unsubscribe
    assert Store.unsubscribe_eds(store, self()) == :ok

    # ...and we're no longer subscribed
    %Resources{subscribers: subscribers} = get_resources(store, :eds)
    assert subscribers == MapSet.new()
  end
end
