defmodule Relay.Marathon.StoreTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.{App, Store, Task}
  alias Relay.{Publisher, Resources}

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
    port_indices: [0],
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

    {:ok, pub} = start_supervised(Publisher)
    # Subscribe to the Publisher so that we can check when it gets updated
    for xds <- [:rds, :cds, :eds] do
      Publisher.subscribe(pub, xds, self())
      # Ignore the empty state message
      receive do
        {^xds, _, _} -> :ok
      end
    end

    {:ok, res} = start_supervised({Resources, publisher: pub})
    {:ok, store} = start_supervised({Store, resources: res})
    %{pub: pub, res: res, store: store}
  end

  defp get_state(store) do
    {:ok, state} = GenServer.call(store, :_get_state)
    state
  end

  defp assert_empty_state(store),
    do: assert(get_state(store) == %Store.State{apps: %{}, tasks: %{}, app_tasks: %{}})

  defp assert_app_updates(app_version) do
    # Assert we receive RDS, CDS, & EDS messages but without any endpoints
    assert_receive_routes(app_version)
    assert_receive_clusters(app_version)
    assert_receive_endpoints_empty(app_version)
  end

  defp assert_task_updates(task_version) do
    # Assert we receive RDS, CDS, & EDS messages but with endpoints this time
    assert_receive_routes(task_version)
    assert_receive_clusters(task_version)
    assert_receive_endpoints(task_version)
  end

  defp assert_receive_routes(version) do
    alias Envoy.Api.V2.RouteConfiguration
    alias Envoy.Api.V2.Route.{RedirectAction, Route, RouteAction, RouteMatch, VirtualHost}

    assert_receive {
                     :rds,
                     ^version,
                     [
                       %RouteConfiguration{
                         name: "http",
                         virtual_hosts: [
                           %VirtualHost{
                             domains: ["mc2.example.org"],
                             routes: [
                               %Route{
                                 action:
                                   {:route,
                                    %RouteAction{
                                      cluster_specifier: {:cluster, "/marathon-acme_0"}
                                    }},
                                 match: %RouteMatch{
                                   path_specifier: {:prefix, "/.well-known/acme-challenge/"}
                                 }
                               },
                               %Route{
                                 action: {:redirect, %RedirectAction{https_redirect: true}},
                                 match: %RouteMatch{path_specifier: {:prefix, "/"}}
                               }
                             ]
                           }
                         ]
                       },
                       %RouteConfiguration{
                         name: "https",
                         virtual_hosts: [
                           %VirtualHost{
                             domains: ["mc2.example.org"],
                             routes: [
                               %Route{
                                 action:
                                   {:route, %RouteAction{cluster_specifier: {:cluster, "/mc2_0"}}},
                                 match: %RouteMatch{path_specifier: {:prefix, "/"}}
                               }
                             ]
                           }
                         ]
                       }
                     ]
                   },
                   100
  end

  defp assert_receive_clusters(version) do
    alias Envoy.Api.V2.Cluster
    assert_receive {:cds, ^version, [%Cluster{name: "/mc2_0"}]}, 100
  end

  defp assert_receive_endpoints_empty(version) do
    alias Envoy.Api.V2.ClusterLoadAssignment
    alias Envoy.Api.V2.Endpoint.LocalityLbEndpoints

    assert_receive {:eds, ^version,
                    [
                      %ClusterLoadAssignment{
                        cluster_name: "/mc2_0",
                        endpoints: [%LocalityLbEndpoints{lb_endpoints: []}]
                      }
                    ]},
                   100
  end

  defp assert_receive_endpoints(version) do
    alias Envoy.Api.V2.ClusterLoadAssignment
    alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}
    alias Envoy.Api.V2.Core.{Address, SocketAddress}

    assert_receive {:eds, ^version,
                    [
                      %ClusterLoadAssignment{
                        cluster_name: "/mc2_0",
                        endpoints: [
                          %LocalityLbEndpoints{
                            lb_endpoints: [
                              %LbEndpoint{
                                endpoint: %Endpoint{
                                  address: %Address{
                                    address:
                                      {:socket_address,
                                       %SocketAddress{
                                         address: "10.70.4.100",
                                         port_specifier: {:port_value, 15979}
                                       }}
                                  }
                                }
                              }
                            ]
                          }
                        ]
                      }
                    ]},
                   100
  end

  defp assert_empty_updates do
    assert_receive {:rds, "", []}, 100
    assert_receive {:cds, "", []}
    assert_receive {:eds, "", []}
  end

  defp refute_updates do
    refute_receive {:rds, _, _}, 100
    refute_receive {:cds, _, _}, 100
    refute_receive {:eds, _, _}, 100
  end

  test "update app not existing", %{store: store} do
    %App{id: app_id, version: app_version} = @test_app

    assert Store.update_app(store, @test_app) == :ok

    assert get_state(store) == %Store.State{
             apps: %{app_id => @test_app},
             app_tasks: %{app_id => MapSet.new()},
             tasks: %{}
           }

    assert_app_updates(app_version)
  end

  test "update app same version", %{store: store} do
    %App{id: app_id, version: app_version} = @test_app

    assert Store.update_app(store, @test_app) == :ok
    assert Store.update_app(store, @test_app) == :ok

    assert get_state(store) == %Store.State{
             apps: %{app_id => @test_app},
             app_tasks: %{app_id => MapSet.new()},
             tasks: %{}
           }

    # We should receive one update...
    assert_app_updates(app_version)

    # ...but no more than that
    refute_updates()
  end

  test "update app new version", %{store: store} do
    %App{id: app_id, version: app_version} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    assert_app_updates(app_version)

    app2_version = "2017-11-10T15:06:31.066Z"
    assert app2_version > app_version
    app2 = %{@test_app | version: app2_version}

    assert Store.update_app(store, app2) == :ok

    assert %Store.State{apps: %{^app_id => ^app2}} = get_state(store)
    assert_app_updates(app2_version)
  end

  test "delete app", %{store: store} do
    %App{id: app_id, version: app_version} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    assert_app_updates(app_version)

    assert Store.delete_app(store, app_id) == :ok
    assert_empty_state(store)
    assert_empty_updates()
  end

  test "delete app does not exist", %{store: store} do
    %App{id: app_id} = @test_app

    assert Store.delete_app(store, app_id) == :ok

    assert_empty_state(store)
    # No updates since nothing was ever stored
    refute_updates()
  end

  test "update task not existing", %{store: store} do
    %App{version: app_version} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    assert_app_updates(app_version)

    %Task{id: task_id, app_id: app_id, version: task_version} = @test_task
    assert Store.update_task(store, @test_task) == :ok

    assert get_state(store) == %Store.State{
             apps: %{app_id => @test_app},
             tasks: %{task_id => @test_task},
             app_tasks: %{app_id => MapSet.new([task_id])}
           }
    # In this case the versions are all the task version because that is newer
    assert_task_updates(task_version)
  end

  test "update task without app", %{store: store} do
    %Task{id: task_id, app_id: app_id} = @test_task

    import ExUnit.CaptureLog

    assert capture_log(fn ->
             assert Store.update_task(store, @test_task) == :ok
           end) =~ "Unable to find app '#{app_id}' for task '#{task_id}'. Task update ignored."

    assert_empty_state(store)
    # No updates since nothing was ever stored
    refute_updates()
  end

  test "update task same version", %{store: store} do
    %App{version: app_version} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    assert_app_updates(app_version)

    %Task{id: task_id, version: task_version} = @test_task
    assert Store.update_task(store, @test_task) == :ok
    assert Store.update_task(store, @test_task) == :ok

    assert %Store.State{tasks: %{^task_id => @test_task}} = get_state(store)
    # There should be only one update due to the `update_task` calls
    assert_task_updates(task_version)
    refute_updates()
  end

  test "update task new version", %{store: store} do
    %App{version: app_version} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    assert_app_updates(app_version)

    %Task{id: task_id, version: task_version} = @test_task
    assert Store.update_task(store, @test_task) == :ok
    assert_task_updates(task_version)

    task2_version = "2017-11-10T15:06:31.066Z"
    assert task2_version > task_version
    task2 = %{@test_task | version: task2_version}

    assert Store.update_task(store, task2)

    assert %Store.State{tasks: %{^task_id => ^task2}} = get_state(store)
    assert_task_updates(task2_version)
  end

  test "delete task", %{store: store} do
    %App{version: app_version} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    assert_app_updates(app_version)

    %Task{id: task_id, app_id: app_id, version: task_version} = @test_task
    assert Store.update_task(store, @test_task) == :ok
    assert_task_updates(task_version)

    assert Store.delete_task(store, task_id) == :ok

    empty_set = MapSet.new()

    assert %Store.State{
             apps: %{^app_id => @test_app},
             tasks: %{},
             app_tasks: %{^app_id => ^empty_set}
           } = get_state(store)
    # Only app information available now
    assert_app_updates(app_version)
  end

  test "delete task does not exist", %{store: store} do
    assert Store.delete_task(store, "foo") == :ok

    assert_empty_state(store)
    # No updates since nothing was ever stored
    refute_updates()
  end

  test "delete app deletes tasks", %{store: store} do
    %App{id: app_id, version: app_version} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    assert_app_updates(app_version)

    %Task{version: task_version} = @test_task
    assert Store.update_task(store, @test_task) == :ok
    assert_task_updates(task_version)

    assert Store.delete_app(store, app_id) == :ok

    assert_empty_state(store)
    assert_empty_updates()
  end

  test "get apps", %{store: store} do
    app2 = %{@test_app | id: "/mc1"}

    assert Store.update_app(store, @test_app) == :ok
    assert Store.update_app(store, app2) == :ok

    assert store |> get_state() |> Store.State.get_apps() == [app2, @test_app]
  end

  test "get apps and tasks", %{store: store} do
    app2 = %{@test_app | id: "/mc1"}
    task2 = %{@test_task | id: "mc2.00000000"}

    assert Store.update_app(store, @test_app) == :ok
    assert Store.update_app(store, app2) == :ok
    assert Store.update_task(store, @test_task) == :ok
    assert Store.update_task(store, task2) == :ok

    assert store |> get_state() |> Store.State.get_apps_and_tasks() == [
             {app2, []},
             {@test_app, [task2, @test_task]}
           ]
  end
end
