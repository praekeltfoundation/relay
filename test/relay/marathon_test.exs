defmodule Relay.MarathonTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.{App, State, Task}

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

  describe "Marathon.State" do
    test "add app" do
      %App{id: app_id} = @test_app

      assert {nil, state} = State.put_app(%State{}, @test_app)

      assert state == %State{
        apps: %{app_id => @test_app},
        app_tasks: %{app_id => MapSet.new()},
        tasks: %{}
      }
    end

    test "update app same version" do
      %App{version: app_version} = @test_app

      assert {nil, state} = State.put_app(%State{}, @test_app)
      assert {^app_version, ^state} = State.put_app(state, @test_app)
    end

    test "update app new version" do
      %App{id: app_id, version: app_version} = @test_app

      assert {nil, state} = State.put_app(%State{}, @test_app)

      app2_version = "2017-11-10T15:06:31.066Z"
      assert app2_version > app_version
      app2 = %{@test_app | version: app2_version}

      assert {^app_version, state2} = State.put_app(state, app2)

      assert %State{apps: %{^app_id => ^app2}} = state2
    end

    test "delete app" do
      assert {nil, state} = State.put_app(%State{}, @test_app)

      assert State.delete_app(state, @test_app) == %State{apps: %{}, tasks: %{}, app_tasks: %{}}
    end

    test "delete app does not exist" do
      assert State.delete_app(%State{}, @test_app) == %State{apps: %{}, tasks: %{}, app_tasks: %{}}
    end

    test "add task" do
      assert {nil, state} = State.put_app(%State{}, @test_app)

      %Task{id: task_id, app_id: app_id} = @test_task
      assert {nil, state2} = State.put_task!(state, @test_task)

      assert state2 == %State{
        apps: %{app_id => @test_app},
        tasks: %{task_id => @test_task},
        app_tasks: %{app_id => MapSet.new([task_id])}
      }
    end

    test "add task without app" do
      assert_raise KeyError, "key \"/mc2\" not found in: %{}", fn ->
        State.put_task!(%State{}, @test_task)
      end
    end

    test "update task same version" do
      assert {nil, state} = State.put_app(%State{}, @test_app)

      %Task{version: task_version} = @test_task
      assert {nil, state2} = State.put_task!(state, @test_task)

      assert {^task_version, ^state2} = State.put_task!(state2, @test_task)
    end

    test "update task new version" do
      assert {nil, state} = State.put_app(%State{}, @test_app)

      %Task{id: task_id, version: task_version} = @test_task
      assert {nil, state2} = State.put_task!(state, @test_task)

      task2_version = "2017-11-10T15:06:31.066Z"
      assert task2_version > task_version
      task2 = %{@test_task | version: task2_version}

      assert {^task_version, state3} = State.put_task!(state2, task2)

      assert %State{tasks: %{^task_id => ^task2}} = state3
    end

    test "delete task" do
      assert {nil, state} = State.put_app(%State{}, @test_app)

      %Task{app_id: app_id} = @test_task
      assert {nil, state2} = State.put_task!(state, @test_task)

      assert State.delete_task!(state2, @test_task) == %State{
        apps: %{app_id => @test_app},
        tasks: %{},
        app_tasks: %{app_id => MapSet.new()}
      }
    end

    test "delete task does not exist" do
      assert {nil, state} = State.put_app(%State{}, @test_app)

      %Task{app_id: app_id} = @test_task

      assert State.delete_task!(state, @test_task) == %State{
        apps: %{app_id => @test_app},
        tasks: %{},
        app_tasks: %{app_id => MapSet.new()}
      }
    end

    test "delete task does not exist without app" do
      assert_raise KeyError, "key \"/mc2\" not found in: %{}", fn ->
        State.delete_task!(%State{}, @test_task)
      end
    end

    test "delete app deletes tasks" do
      assert {nil, state} = State.put_app(%State{}, @test_app)
      assert {nil, state2} = State.put_task!(state, @test_task)

      assert State.delete_app(state2, @test_app) == %State{apps: %{}, tasks: %{}, app_tasks: %{}}
    end
  end
end
