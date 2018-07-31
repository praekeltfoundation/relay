Code.require_file(Path.join([__DIR__, "..", "marathon_client", "marathon_client_helper.exs"]))

defmodule Relay.SupervisorTest do
  use ExUnit.Case, async: false

  alias Relay.{Supervisor, Publisher, Resolver, Resources, Certs, Marathon}

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

  defmodule Liveness do
    alias Relay.{Supervisor, Publisher, Resolver, Resources, Certs, Marathon}

    @sups [Supervisor, Supervisor.SubSupervisor, Marathon.Supervisor]
    @procs_top [Publisher, Resolver, Resources]
    @procs_sub [Certs.Filesystem, GRPC.Server.Supervisor]
    @procs_marathon [Marathon.Store, Marathon]
    @all_procs Enum.concat([@sups, @procs_top, @procs_sub, @procs_marathon])

    def marathon_tree(), do: [Marathon.Supervisor | @procs_marathon]
    def sub_tree(), do: [Supervisor.SubSupervisor | @procs_sub ++ marathon_tree()]

    def monitor_procs() do
      @all_procs
      |> Enum.map(fn name ->
        pid = Process.whereis(name)
        {name, {pid, Process.monitor(pid)}}
      end)
    end

    def kill(procs, name) do
      {pid, _} = Keyword.fetch!(procs, name)
      Process.exit(pid, :kill)
    end

    def assert_exited(procs, killed_names, shutdown_names) do
      {killed_procs, rest} = Keyword.split(procs, killed_names)
      {shutdown_procs, live_procs} = Keyword.split(rest, shutdown_names)

      # Exited procs must have generated a :DOWN message.
      Enum.each(killed_procs, &proc_exited(&1, :killed))
      Enum.each(shutdown_procs, &proc_exited(&1, :shutdown))

      # Live procs must still have the same pid.
      Enum.each(live_procs, fn {name, {pid, _}} ->
        assert Process.alive?(pid), "Expected #{name} (#{inspect(pid)}) to be alive"
      end)
    end

    defp proc_exited({_, {pid, ref}}, reason),
      do: assert_receive({:DOWN, ^ref, :process, ^pid, ^reason}, 1_000)

    defp sup_live?(sup) do
      case Elixir.Supervisor.count_children(sup) do
        %{specs: n, active: n} -> true
        _ -> false
      end
    catch
      # `Supervisor.count_children` uses `:gen.call` under the hood, which
      # monitors the process we're querying during the query. This is fine if
      # we're part of a supervision tree, but for these tests we don't really
      # want to crash if the process we're querying is down. To get around
      # this, we catch exits (which is almost always a terrible idea) and
      # return `false` instead.
      :exit, _ ->
        false
    end

    def wait_until_live do
      case Enum.any?(@sups, &sup_live?/1) do
        true ->
          :ok

        _ ->
          Process.sleep(10)
          wait_until_live()
      end
    end
  end

  defp confirm_process_restarts(process_to_kill, processes_that_restart) do
    Process.flag(:trap_exit, true)
    procs = Liveness.monitor_procs()
    # Wait for all the initial interaction to finish
    Process.sleep(50)

    # Kill the specified process to observe the restart behaviour
    Liveness.kill(procs, process_to_kill)

    # The process we killed and eveything that depends on it exit
    Liveness.assert_exited(procs, [process_to_kill], processes_that_restart)

    # Wait until everything's back up before returning
    Liveness.wait_until_live()
  end

  test "when the Publisher exits everything is restarted" do
    confirm_process_restarts(Publisher, [Resolver, Resources | Liveness.sub_tree()])
    assert_example_response()
  end

  test "when Resources exits everything except Publisher is restarted" do
    confirm_process_restarts(Resources, Liveness.sub_tree())
    assert_example_response()
  end

  test "when Certs.Filesystem exits it is restarted" do
    confirm_process_restarts(Certs.Filesystem, [])
    assert_example_response()
  end

  test "when Marathon exits it is restarted" do
    confirm_process_restarts(Marathon, [])
    assert_example_response()
  end

  test "when Marathon.Store exits Marathon is also restarted" do
    confirm_process_restarts(Marathon.Store, [Marathon])
    assert_example_response()
  end

  test "when the GRPC supervisor exits it is restarted" do
    # Capture the error logged when we kill the supervisor
    assert capture_log(fn ->
             confirm_process_restarts(GRPC.Server.Supervisor, [])
             # The log entry we capture is apparently sent *after* the GRPC
             # supervisor exits, so we need to wait a bit for it to arrive.
             Process.sleep(50)
           end) =~ ~r/\[error\] GenServer #PID<\S*> terminating\n\*\* \(stop\) killed/

    assert_example_response()
  end
end
