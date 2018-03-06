defmodule Relay.Marathon.StoreTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.{App, Store, Task}

  @test_app %App{
    id: "/mc2",
    labels: %{
      "HAPROXY_0_REDIRECT_TO_HTTPS" => "true",
      "HAPROXY_0_VHOST" => "mc2.example.org",
      "HAPROXY_GROUP" => "external",
      "MARATHON_ACME_0_DOMAIN" => "mc2.example.org"
    },
    networking_mode: :"container/bridge",
    ports_list: [80],
    version: "2017-11-08T15:06:31.066Z"
  }

  @test_task %Task{
    address: "10.70.4.100",
    app_id: "/mc2",
    id: "mc2.be753491-1325-11e8-b5d6-4686525b33db",
    ports: [15979],
    version: "2017-11-09T08:43:59.890Z"
  }

  setup do
    TestHelpers.override_log_level(:warn)

    {:ok, store} = start_supervised(Store)
    %{store: store}
  end

  defp get_state(store) do
    {:ok, state} = GenServer.call(store, :_get_state)
    state
  end

  defp assert_empty_state(store),
    do: assert get_state(store) == %Store.State{apps: %{}, tasks: %{}, app_tasks: %{}}

  test "update app not existing", %{store: store} do
    %App{id: app_id} = @test_app

    assert Store.update_app(store, @test_app) == :ok

    assert get_state(store) == %Store.State{
      apps: %{app_id => @test_app},
      app_tasks: %{app_id => MapSet.new()},
      tasks: %{}
    }
  end

  test "update app same version", %{store: store} do
    %App{id: app_id} = @test_app

    assert Store.update_app(store, @test_app) == :ok
    assert Store.update_app(store, @test_app) == :ok

    assert get_state(store) == %Store.State{
      apps: %{app_id => @test_app},
      app_tasks: %{app_id => MapSet.new()},
      tasks: %{}
    }
  end

  test "update app new version", %{store: store} do
    %App{id: app_id, version: app_version} = @test_app

    assert Store.update_app(store, @test_app) == :ok

    app2_version = "2017-11-10T15:06:31.066Z"
    assert app2_version > app_version
    app2 = %{@test_app | version: app2_version}

    assert Store.update_app(store, app2) == :ok

    assert %Store.State{apps: %{^app_id => ^app2}} = get_state(store)
  end

  test "delete app", %{store: store} do
    %App{id: app_id} = @test_app

    assert Store.update_app(store, @test_app) == :ok
    assert Store.delete_app(store, app_id) == :ok

    assert_empty_state(store)
  end

  test "delete app does not exist", %{store: store} do
    %App{id: app_id} = @test_app

    assert Store.delete_app(store, app_id) == :ok

    assert_empty_state(store)
  end

  test "update task not existing", %{store: store} do
    assert Store.update_app(store, @test_app) == :ok

    %Task{id: task_id, app_id: app_id} = @test_task
    assert Store.update_task(store, @test_task) == :ok

    assert get_state(store) == %Store.State{
      apps: %{app_id => @test_app},
      tasks: %{task_id => @test_task},
      app_tasks: %{app_id => MapSet.new([task_id])}
    }
  end

  test "update task without app", %{store: store} do
    %Task{id: task_id, app_id: app_id} = @test_task

    import ExUnit.CaptureLog
    assert capture_log(fn ->
      assert Store.update_task(store, @test_task) == :ok
    end) =~ "Unable to find app '#{app_id}' for task '#{task_id}'. Task update ignored."

    assert_empty_state(store)
  end

  test "update task same version", %{store: store} do
    assert Store.update_app(store, @test_app) == :ok

    %Task{id: task_id} = @test_task
    assert Store.update_task(store, @test_task) == :ok
    assert Store.update_task(store, @test_task) == :ok

    assert %Store.State{tasks: %{^task_id => @test_task}} = get_state(store)
  end

  test "update task new version", %{store: store} do
    assert Store.update_app(store, @test_app) == :ok

    %Task{id: task_id, version: task_version} = @test_task
    assert Store.update_task(store, @test_task) == :ok

    task2_version = "2017-11-10T15:06:31.066Z"
    assert task2_version > task_version
    task2 = %{@test_task | version: task2_version}

    assert Store.update_task(store, task2)

    assert %Store.State{tasks: %{^task_id => ^task2}} = get_state(store)
  end

  test "delete task", %{store: store} do
    assert Store.update_app(store, @test_app) == :ok

    %Task{id: task_id, app_id: app_id} = @test_task
    assert Store.update_task(store, @test_task) == :ok
    assert Store.delete_task(store, task_id) == :ok

    empty_set = MapSet.new()
    assert %Store.State{
      apps: %{^app_id => @test_app},
      tasks: %{},
      app_tasks: %{^app_id => ^empty_set}
    } = get_state(store)
  end

  test "delete task does not exist", %{store: store} do
    assert Store.delete_task(store, "foo") == :ok

    assert_empty_state(store)
  end

  test "delete app deletes tasks", %{store: store} do
    %App{id: app_id} = @test_app

    assert Store.update_app(store, @test_app) == :ok
    assert Store.update_task(store, @test_task) == :ok

    assert Store.delete_app(store, app_id) == :ok

    assert_empty_state(store)
  end
end
