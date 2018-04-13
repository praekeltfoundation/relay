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

  defp get_state_version(store), do: store |> get_state() |> Map.fetch!(:version)

  defp assert_empty_state(store),
    do: assert(%Store.State{apps: %{}, app_tasks: %{}} = get_state(store))

  defp assert_app_updates(version) do
    # Assert we receive RDS, CDS, & EDS messages but without any endpoints
    assert_receive_routes(version)
    assert_receive_clusters(version)
    assert_receive_endpoints_empty(version)
  end

  defp assert_task_updates(version) do
    # Assert we receive RDS, CDS, & EDS messages but with endpoints this time
    assert_receive_routes(version)
    assert_receive_clusters(version)
    assert_receive_endpoints(version)
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

  defp assert_empty_updates(version) do
    alias Envoy.Api.V2.RouteConfiguration

    # Unfortunately the RDS response is not completely empty
    assert_receive {:rds, ^version,
                    [
                      %RouteConfiguration{name: "http", virtual_hosts: []},
                      %RouteConfiguration{name: "https", virtual_hosts: []}
                    ]},
                   100

    assert_receive {:cds, ^version, []}
    assert_receive {:eds, ^version, []}
  end

  defp refute_updates do
    refute_receive {:rds, _, _}, 100
    refute_receive {:cds, _, _}, 100
    refute_receive {:eds, _, _}, 100
  end

  test "sync", %{store: store} do
    %App{id: app_id} = @test_app
    %Task{id: task_id} = @test_task

    assert_empty_state(store)
    version0 = get_state_version(store)

    assert Store.sync(store, [{@test_app, [@test_task]}]) == :ok

    # App and task stored in state
    assert %Store.State{
             version: version1,
             apps: %{^app_id => @test_app},
             app_tasks: %{^app_id => %{^task_id => @test_task}}
           } = get_state(store)

    # Version has increased
    assert version1 > version0

    # An update was sent
    assert_task_updates(version1)
  end

  test "update app not existing", %{store: store} do
    %App{id: app_id} = @test_app
    version0 = get_state_version(store)

    assert Store.update_app(store, @test_app) == :ok

    # App is stored in state
    assert %Store.State{
             version: version1,
             apps: %{^app_id => @test_app},
             app_tasks: %{^app_id => %{}}
           } = get_state(store)

    # Version has increased
    assert version1 > version0

    # An update was sent
    assert_app_updates(version1)
  end

  test "update app same version", %{store: store} do
    %App{id: app_id} = @test_app

    assert Store.update_app(store, @test_app) == :ok

    assert %Store.State{
             version: version,
             apps: %{^app_id => @test_app},
             app_tasks: %{^app_id => %{}}
           } = get_state(store)

    # We should receive one update...
    assert_app_updates(version)

    assert Store.update_app(store, @test_app) == :ok
    # ...state version should not have changed
    assert %Store.State{
             version: ^version,
             apps: %{^app_id => @test_app},
             app_tasks: %{^app_id => %{}}
           } = get_state(store)

    # ...and no updates
    refute_updates()
  end

  test "update app new version", %{store: store} do
    %App{id: app_id, version: app_version} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    version1 = get_state_version(store)
    assert_app_updates(version1)

    app2_version = "2017-11-10T15:06:31.066Z"
    assert app2_version > app_version
    app2 = %{@test_app | version: app2_version}

    assert Store.update_app(store, app2) == :ok

    assert %Store.State{version: version2, apps: %{^app_id => ^app2}} = get_state(store)

    assert version2 > version1
    assert_app_updates(version2)
  end

  test "get app not existing", %{store: store} do
    assert Store.get_app(store, "/mc2") == {:ok, nil}
  end

  test "get app", %{store: store} do
    %App{id: app_id} = @test_app

    assert Store.update_app(store, @test_app) == :ok

    assert Store.get_app(store, app_id) == {:ok, @test_app}
  end

  test "delete app", %{store: store} do
    %App{id: app_id} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    version1 = get_state_version(store)
    assert_app_updates(version1)

    assert Store.delete_app(store, app_id) == :ok
    assert_empty_state(store)

    # Version has increased and an update sent
    version2 = get_state_version(store)
    assert version2 > version1
    assert_empty_updates(version2)
  end

  test "delete app does not exist", %{store: store} do
    %App{id: app_id} = @test_app

    assert Store.delete_app(store, app_id) == :ok

    assert_empty_state(store)
    # No updates since nothing was ever stored
    refute_updates()
  end

  test "update task not existing", %{store: store} do
    assert Store.update_app(store, @test_app) == :ok
    version1 = get_state_version(store)
    assert_app_updates(version1)

    %Task{id: task_id, app_id: app_id} = @test_task
    assert Store.update_task(store, @test_task) == :ok

    assert %Store.State{
             version: version2,
             apps: %{^app_id => @test_app},
             app_tasks: %{^app_id => %{^task_id => @test_task}}
           } = get_state(store)

    assert version2 > version1
    assert_task_updates(version2)
  end

  test "update task without app", %{store: store} do
    %Task{app_id: app_id} = @test_task

    import ExUnit.CaptureLog

    assert capture_log(fn ->
             assert {{{:badkey, ^app_id}, _}, _} =
                      catch_exit(Store.update_task(store, @test_task))
           end) =~ ~r"GenServer .+ terminating"

    # No updates since nothing was ever stored
    refute_updates()
  end

  test "update task same version", %{store: store} do
    assert Store.update_app(store, @test_app) == :ok
    store |> get_state_version() |> assert_app_updates()

    %Task{id: task_id, app_id: app_id} = @test_task
    assert Store.update_task(store, @test_task) == :ok
    version = get_state_version(store)
    # First task addition triggers update...
    assert_task_updates(version)

    assert Store.update_task(store, @test_task) == :ok

    # ...version and task haven't changed
    assert %Store.State{version: ^version, app_tasks: %{^app_id => %{^task_id => @test_task}}} =
             get_state(store)

    # ...and no further updates
    refute_updates()
  end

  test "update task new version", %{store: store} do
    assert Store.update_app(store, @test_app) == :ok
    store |> get_state_version() |> assert_app_updates()

    %Task{id: task_id, app_id: app_id, version: task_version} = @test_task
    assert Store.update_task(store, @test_task) == :ok
    version1 = get_state_version(store)
    assert_task_updates(version1)

    task2_version = "2017-11-10T15:06:31.066Z"
    assert task2_version > task_version
    task2 = %{@test_task | version: task2_version}

    assert Store.update_task(store, task2)

    assert %Store.State{version: version2, app_tasks: %{^app_id => %{^task_id => ^task2}}} =
             get_state(store)

    assert version2 > version1
    assert_task_updates(version2)
  end

  test "delete task", %{store: store} do
    assert Store.update_app(store, @test_app) == :ok
    store |> get_state_version() |> assert_app_updates()

    %Task{id: task_id, app_id: app_id} = @test_task
    assert Store.update_task(store, @test_task) == :ok
    version1 = get_state_version(store)
    assert_task_updates(version1)

    assert Store.delete_task(store, task_id, app_id) == :ok

    assert %Store.State{
             version: version2,
             apps: %{^app_id => @test_app},
             app_tasks: %{^app_id => %{}}
           } = get_state(store)

    assert version2 > version1
    # Only app information available now
    assert_app_updates(version2)
  end

  test "delete task does not exist", %{store: store} do
    %App{id: app_id} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    store |> get_state_version() |> assert_app_updates()

    assert Store.delete_task(store, "foo", app_id) == :ok
    # No updates since nothing was deleted
    refute_updates()
  end

  test "delete task without app", %{store: store} do
    assert Store.delete_task(store, "foo", "bar") == :ok

    assert_empty_state(store)
    # No updates since nothing was ever stored
    refute_updates()
  end

  test "delete app deletes tasks", %{store: store} do
    %App{id: app_id} = @test_app
    assert Store.update_app(store, @test_app) == :ok
    store |> get_state_version() |> assert_app_updates()

    assert Store.update_task(store, @test_task) == :ok
    version1 = get_state_version(store)
    assert_task_updates(version1)

    assert Store.delete_app(store, app_id) == :ok

    assert_empty_state(store)

    version2 = get_state_version(store)
    assert version2 > version1
    assert_empty_updates(version2)
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
