Code.require_file(Path.join([__DIR__, "..", "marathon_client", "marathon_client_helper.exs"]))

defmodule Relay.SupervisorTest do
  use ExUnit.Case, async: false

  alias Relay.{Supervisor, Publisher, Resources, Certs, Marathon}
  alias Relay.Supervisor.FrontendSupervisor

  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}
  alias Envoy.Api.V2.ClusterDiscoveryService.Stub, as: CDSStub
  alias Envoy.Api.V2.ListenerDiscoveryService.Stub, as: LDSStub
  alias Envoy.Api.V2.{Cluster, Listener}

  import ExUnit.CaptureLog

  @addr "127.0.0.1"
  @port 12345

  @test_app %{
    "id" => "/mc2",
    "backoffFactor" => 1.15,
    "backoffSeconds" => 1,
    "container" => %{
      "type" => "DOCKER",
      "docker" => %{
        "forcePullImage" => true,
        "image" => "praekeltfoundation/mc2:release-3.11.2",
        "parameters" => [
          %{
            "key" => "add-host",
            "value" => "servicehost:172.17.0.1"
          }
        ],
        "privileged" => false
      },
      "volumes" => [],
      "portMappings" => [
        %{
          "containerPort" => 80,
          "hostPort" => 0,
          "labels" => %{},
          "protocol" => "tcp",
          "servicePort" => 10003
        }
      ]
    },
    "cpus" => 0.1,
    "disk" => 0,
    "env" => %{
      "MESOS_MARATHON_HOST" => "http://master.mesos:8080",
      "DEBUG" => "False",
      "PROJECT_ROOT" => "/deploy/"
    },
    "executor" => "",
    "instances" => 1,
    "labels" => %{
      #      "MARATHON_ACME_0_DOMAIN" => "mc2.example.org",
      #      "HAPROXY_0_REDIRECT_TO_HTTPS" => "true",
      "HAPROXY_0_VHOST" => "mc2.example.org",
      "HAPROXY_GROUP" => "external"
    },
    "maxLaunchDelaySeconds" => 3600,
    "mem" => 256,
    "gpus" => 0,
    "networks" => [
      %{
        "mode" => "container/bridge"
      }
    ],
    "requirePorts" => false,
    "upgradeStrategy" => %{
      "maximumOverCapacity" => 1,
      "minimumHealthCapacity" => 1
    },
    "version" => "2017-11-09T08:43:59.89Z",
    "versionInfo" => %{
      "lastScalingAt" => "2017-11-09T08:43:59.89Z",
      "lastConfigChangeAt" => "2017-11-08T15:06:31.066Z"
    },
    "killSelection" => "YOUNGEST_FIRST",
    "unreachableStrategy" => %{
      "inactiveAfterSeconds" => 300,
      "expungeAfterSeconds" => 600
    },
    "tasksStaged" => 0,
    "tasksRunning" => 1,
    "tasksHealthy" => 0,
    "tasksUnhealthy" => 0,
    "deployments" => []
  }

  @test_task %{
    "ipAddresses" => [
      %{
        "ipAddress" => "172.17.0.9",
        "protocol" => "IPv4"
      }
    ],
    "stagedAt" => "2018-02-16T14:29:06.487Z",
    "state" => "TASK_RUNNING",
    "ports" => [
      15979
    ],
    "startedAt" => "2018-02-16T14:29:09.605Z",
    "version" => "2017-11-09T08:43:59.890Z",
    "id" => "mc2.be753491-1325-11e8-b5d6-4686525b33db",
    "appId" => "/mc2",
    "slaveId" => "d25be2a7-61ce-475f-8b07-d56400c8d744-S1",
    "host" => "10.70.4.100"
  }

  @test_app_endpoints [
    %Relay.Resources.AppEndpoint{
      addresses: [{"10.70.4.100", 15979}],
      domains: ["mc2.example.org"],
      name: "/mc2_0"
    }
  ]

  setup do
    TestHelpers.setup_apps([:grpc, :httpoison])
    TestHelpers.override_log_level(:warn)
    TestHelpers.put_env(:grpc, :start_server, true)

    {_tmpdir, [cert_path]} = TestHelpers.tmpdir_subdirs(["certs"])
    put_certs_config(paths: [cert_path])
    copy_cert("localhost.pem", cert_path)

    # Set up FakeMarathon
    {:ok, fm} = start_supervised(FakeMarathon)

    # Store the test app and task
    FakeMarathon.set_apps(fm, [@test_app])
    FakeMarathon.set_app_tasks(fm, @test_app["id"], [@test_task])

    # Configure the Marathon URL for the FakeMarathon
    marathon_config =
      :relay
      |> Application.fetch_env!(:marathon)
      |> Keyword.put(:urls, [FakeMarathon.base_url(fm)])

    TestHelpers.put_env(:relay, :marathon, marathon_config)

    {:ok, sup} = start_supervised({Supervisor, {@addr, @port}})
    %{supervisor: sup}
  end

  defp put_certs_config(opts) do
    certs_config = Application.fetch_env!(:relay, :certs) |> Keyword.merge(opts)
    TestHelpers.put_env(:relay, :certs, certs_config)
  end

  defp copy_cert(cert_file, cert_path) do
    src = TestHelpers.support_path(cert_file)
    dst = Path.join(cert_path, cert_file)
    File.cp!(src, dst)
  end

  defp cert_info_from_file(cert_file) do
    cert_bundle = cert_file |> TestHelpers.support_path() |> File.read!()

    %Resources.CertInfo{
      domains: cert_bundle |> Certs.get_end_entity_hostnames(),
      key: cert_bundle |> Certs.get_key() |> get_ok() |> Certs.pem_encode(),
      cert_chain: cert_bundle |> Certs.get_certs() |> Certs.pem_encode()
    }
  end

  defp get_ok(thing) do
    assert {:ok, got} = thing
    got
  end

  defp assert_example_response do
    assert_cds_response(Resources.CDS.clusters(@test_app_endpoints))
    assert_lds_response(Resources.LDS.listeners([cert_info_from_file("localhost.pem")]))
  end

  defp assert_cds_response(clusters) do
    {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{@port}")
    stream = channel |> CDSStub.stream_clusters()
    GRPC.Stub.send_request(stream, DiscoveryRequest.new())

    assert {:ok, result_stream} = GRPC.Stub.recv(stream)
    assert [{:ok, response}] = Enum.take(result_stream, 1)
    assert %DiscoveryResponse{resources: resources} = response

    assert resources |> Enum.map(fn any_res -> Cluster.decode(any_res.value) end) == clusters
  end

  defp assert_lds_response(listeners) do
    {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{@port}")
    stream = channel |> LDSStub.stream_listeners()
    GRPC.Stub.send_request(stream, DiscoveryRequest.new())

    assert {:ok, result_stream} = GRPC.Stub.recv(stream)
    assert [{:ok, response}] = Enum.take(result_stream, 1)
    assert %DiscoveryResponse{resources: resources} = response

    assert resources |> Enum.map(fn any_res -> Listener.decode(any_res.value) end) == listeners
  end

  defp port_blocker(wait_time) do
    caller = self()

    task =
      Task.async(fn ->
        {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
        send(caller, :inet.port(socket))
        Process.sleep(wait_time)
        :ok = :gen_tcp.close(socket)
      end)

    assert_receive {:ok, port}, 50
    {task, port}
  end

  defp extract_reason(reason) do
    case reason do
      {reason, {:child, _, _, _, _, _, _, _}} -> extract_reason(reason)
      {:shutdown, {:failed_to_start_child, _, reason}} -> extract_reason(reason)
      reason -> reason
    end
  end

  defp wait_until_live do
    case procs_live?(Supervisor) and procs_live?(FrontendSupervisor) do
      true ->
        :ok

      _ ->
        Process.sleep(10)
        wait_until_live()
    end
  end

  defp procs_live?(sup) do
    case Elixir.Supervisor.count_children(sup) do
      %{specs: n, active: n} -> true
      _ -> false
    end
  catch
    # `Supervisor.count_children` uses `:gen.call` under the hood, which
    # monitors the process we're querying during the query. This is fine if
    # we're part of a supervision tree, but for these tests we don't really
    # want to crash if the process we're querying is down. To get around this,
    # we catch exits (which is almost always a terrible idea) and return
    # `false` instead.
    :exit, _ ->
      false
  end

  defp monitor_by_name(name), do: name |> Process.whereis() |> Process.monitor()

  defp kill_by_name(name), do: name |> Process.whereis() |> Process.exit(:kill)

  test "retry listener startup when address is in use" do
    :ok = stop_supervised(Supervisor)

    {blocker_task, port} = port_blocker(100)

    assert capture_log(fn ->
             {:ok, _} = start_supervised({Supervisor, {@addr, port}})
           end) =~ ~r/Failed to start Ranch listener .* :eaddrinuse/

    Task.await(blocker_task)
  end

  test "retry times out after one second" do
    :ok = stop_supervised(Supervisor)

    {blocker_task, port} = port_blocker(1_050)

    assert capture_log(fn ->
             {:error, reason} = start_supervised({Supervisor, {@addr, port}})
             assert {:listen_error, _, :eaddrinuse} = extract_reason(reason)
           end) =~ ~r/Failed to start Ranch listener .* :eaddrinuse/

    Task.await(blocker_task)
  end

  test "when the Publisher exits everything is restarted" do
    Process.flag(:trap_exit, true)

    # Monitor resources, server, and demo
    resources_ref = monitor_by_name(Resources)
    server_ref = monitor_by_name(GRPC.Server.Supervisor)
    marathon_store_ref = monitor_by_name(Marathon.Store)
    marathon_ref = monitor_by_name(Marathon)
    certs_fs_ref = monitor_by_name(Certs.Filesystem)

    # Wait for all the initial interation to finish
    Process.sleep(50)

    # Exit the Publisher process
    kill_by_name(Publisher)

    # Resources, server, and demo quit
    assert_receive {:DOWN, ^resources_ref, :process, _, :shutdown}, 1_000
    assert_receive {:DOWN, ^server_ref, :process, _, :shutdown}, 1_000
    assert_receive {:DOWN, ^certs_fs_ref, :process, _, :shutdown}, 1_000
    assert_receive {:DOWN, ^marathon_store_ref, :process, _, :shutdown}, 1_000
    assert_receive {:DOWN, ^marathon_ref, :process, _, :shutdown}, 1_000

    wait_until_live()

    # Things still work as everything has been restarted
    assert_example_response()
  end

  test "when Resources exits everything except Publisher is restarted" do
    Process.flag(:trap_exit, true)

    publisher_pid = Process.whereis(Publisher)

    # Monitor the server and demo
    server_ref = monitor_by_name(GRPC.Server.Supervisor)
    marathon_store_ref = monitor_by_name(Marathon.Store)
    marathon_ref = monitor_by_name(Marathon)
    certs_fs_ref = monitor_by_name(Certs.Filesystem)

    # Wait for all the initial interation to finish
    Process.sleep(50)

    # Exit the Publisher process
    kill_by_name(Resources)

    # The server and demo quit
    assert_receive {:DOWN, ^server_ref, :process, _, :shutdown}, 1_000
    assert_receive {:DOWN, ^certs_fs_ref, :process, _, :shutdown}, 1_000
    assert_receive {:DOWN, ^marathon_store_ref, :process, _, :shutdown}, 1_000
    assert_receive {:DOWN, ^marathon_ref, :process, _, :shutdown}, 1_000

    # Publisher still happily running
    assert Process.alive?(publisher_pid)

    wait_until_live()

    # Things still work as everything has been restarted
    assert_example_response()
  end

  test "when the GRPC supervisor exits it is restarted" do
    Process.flag(:trap_exit, true)

    publisher_pid = Process.whereis(Publisher)
    resources_pid = Process.whereis(Resources)
    marathon_store_pid = Process.whereis(Marathon.Store)
    marathon_pid = Process.whereis(Marathon)
    certs_fs_pid = Process.whereis(Certs.Filesystem)

    grpc_pid = Process.whereis(GRPC.Server.Supervisor)
    grpc_ref = Process.monitor(grpc_pid)

    # Wait for all the initial interation to finish
    Process.sleep(50)

    # Capture the error logged when we kill the supervisor
    assert capture_log(fn ->
             # Exit the GRPC process
             grpc_pid |> Process.exit(:kill)

             # Check the GRPC supervisor quit
             assert_receive {:DOWN, ^grpc_ref, :process, _, :killed}, 1_000

             # Other things still happily running
             assert Process.alive?(publisher_pid)
             assert Process.alive?(resources_pid)
             assert Process.alive?(marathon_store_pid)
             assert Process.alive?(marathon_pid)
             assert Process.alive?(certs_fs_pid)

             wait_until_live()
           end) =~ ~r/\[error\] GenServer #PID<\S*> terminating\n\*\* \(stop\) killed/

    # Everything else still works because it's all running again
    assert_example_response()
  end

  # We don't bother testing the Marathon stuff, because it's the same behaviour
  # as this.

  test "when Certs.Filesystem exits it is restarted" do
    Process.flag(:trap_exit, true)

    publisher_pid = Process.whereis(Publisher)
    resources_pid = Process.whereis(Resources)
    grpc_pid = Process.whereis(GRPC.Server.Supervisor)
    marathon_store_pid = Process.whereis(Marathon.Store)
    marathon_pid = Process.whereis(Marathon)

    certs_fs_pid = Process.whereis(Certs.Filesystem)
    certs_fs_ref = Process.monitor(certs_fs_pid)

    # Wait for all the initial interation to finish
    Process.sleep(50)

    # Exit the certs_fs process
    certs_fs_pid |> Process.exit(:kill)

    # Check certs_fs quit
    assert_receive {:DOWN, ^certs_fs_ref, :process, _, :killed}, 1_000

    # Other things still happily running
    assert Process.alive?(publisher_pid)
    assert Process.alive?(resources_pid)
    assert Process.alive?(grpc_pid)
    assert Process.alive?(marathon_store_pid)
    assert Process.alive?(marathon_pid)

    wait_until_live()

    # Everything else still works because the state is still available
    assert_example_response()
  end
end
