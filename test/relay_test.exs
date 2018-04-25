Code.require_file(Path.join([__DIR__, "marathon_client", "marathon_client_helper.exs"]))

defmodule RelayTest do
  use ExUnit.Case, async: false

  alias Relay.{Publisher, Resources, Certs, Marathon}

  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}
  alias Envoy.Api.V2.ClusterDiscoveryService.Stub, as: CDSStub
  alias Envoy.Api.V2.ListenerDiscoveryService.Stub, as: LDSStub
  alias Envoy.Api.V2.{Cluster, Listener}

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
    TestHelpers.setup_apps([:cowboy])
    TestHelpers.override_log_level(:warn)
    TestHelpers.put_env(:grpc, :start_server, true)

    {_tmpdir, [cert_path]} = TestHelpers.tmpdir_subdirs(["certs"])
    put_certs_config(paths: [cert_path], sync_period: 1_000)
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

    TestHelpers.put_env(:relay, :marathon, marathon_config, persistent: true)

    listen = Application.get_env(:relay, :listen) |> Keyword.put(:port, @port)
    TestHelpers.put_env(:relay, :listen, listen, persistent: true)
  end

  defp put_certs_config(opts) do
    certs_config = Application.fetch_env!(:relay, :certs) |> Keyword.merge(opts)
    TestHelpers.put_env(:relay, :certs, certs_config, persistent: true)
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

  defp stream_xds do
    {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{@port}")

    %{
      cds: channel |> CDSStub.stream_clusters(),
      lds: channel |> LDSStub.stream_listeners()
    }
  end

  defp recv_xds(streams) do
    %{
      # `GRPC.Stub.recv/1` will block until it receives headers so we must issue
      # a request before we call it.
      cds: streams[:cds] |> do_discovery_request() |> assert_response_stream(),
      lds: streams[:lds] |> do_discovery_request() |> assert_response_stream()
    }
  end

  defp do_discovery_request(stream), do: GRPC.Stub.send_request(stream, DiscoveryRequest.new())

  defp assert_response_stream(stream) do
    # `GRPC.Stub.recv/1` shouldn't be called multiple times on a single stream
    # or else the client gets in a weird state.
    assert {:ok, res_enum} = GRPC.Stub.recv(stream)
    res_enum
  end

  defp assert_cds_request_response(streams, res_enums, clusters) do
    do_discovery_request(streams[:cds])
    assert_cds_response(res_enums, clusters)
  end

  defp assert_lds_request_response(streams, res_enums, clusters) do
    do_discovery_request(streams[:lds])
    assert_lds_response(res_enums, clusters)
  end

  defp assert_cds_response(res_enums, clusters) do
    assert [{:ok, response}] = Enum.take(res_enums[:cds], 1)
    assert %DiscoveryResponse{version_info: version_info, resources: resources} = response

    assert resources |> Enum.map(fn any_res -> Cluster.decode(any_res.value) end) == clusters
    version_info
  end

  defp assert_lds_response(res_enums, listeners) do
    assert [{:ok, response}] = Enum.take(res_enums[:lds], 1)
    assert %DiscoveryResponse{version_info: version_info, resources: resources} = response

    assert resources |> Enum.map(fn any_res -> Listener.decode(any_res.value) end) == listeners
    version_info
  end

  defp expected_clusters, do: Resources.CDS.clusters(@test_app_endpoints)
  defp expected_listeners, do: Resources.LDS.listeners([cert_info_from_file("localhost.pem")])

  test "starting the application starts everything" do
    procs = [
      GRPC.Server.Supervisor,
      Relay.Supervisor,
      Publisher,
      Resources,
      Marathon.Store,
      Marathon,
      Certs.Filesystem
    ]

    # The various processes aren't running before we start the application
    procs
    |> Enum.each(fn id ->
      assert Process.whereis(id) == nil
    end)

    :ok = TestHelpers.setup_apps([:relay])

    # The various processes are running after we start the application
    procs
    |> Enum.each(fn id ->
      assert Process.alive?(Process.whereis(id))
    end)

    streams = stream_xds()
    res_enums = recv_xds(streams)

    assert_cds_response(res_enums, expected_clusters())
    assert_lds_response(res_enums, expected_listeners())
  end

  test "demo app sends multiple updates" do
    :ok = TestHelpers.setup_apps([:relay])

    t0 = Time.utc_now()

    # Initial update
    streams = stream_xds()
    res_enums = recv_xds(streams)
    cds_v_1 = assert_cds_response(res_enums, expected_clusters())
    lds_v_1 = assert_lds_response(res_enums, expected_listeners())

    # Triggered updates
    send(Marathon, :sync)
    cds_v_2 = assert_cds_request_response(streams, res_enums, expected_clusters())
    assert cds_v_2 > cds_v_1
    GenServer.call(Certs.Filesystem, :update_state)
    lds_v_2 = assert_lds_request_response(streams, res_enums, expected_listeners())
    assert lds_v_2 > lds_v_1
    send(Marathon, :sync)
    cds_v_3 = assert_cds_request_response(streams, res_enums, expected_clusters())
    assert cds_v_3 > cds_v_2
    t1 = Time.utc_now()
    assert Time.diff(t1, t0, :milliseconds) < 1_000

    # No scheduled marathon updates yet
    # cds_v_4 = assert_cds_request_response(streams, res_enums, expected_clusters())
    # assert cds_v_4 > cds_v_3

    # Scheduled certs update
    lds_v_3 = assert_lds_request_response(streams, res_enums, expected_listeners())
    assert lds_v_3 > lds_v_2
    t2 = Time.utc_now()
    assert Time.diff(t2, t0, :milliseconds) < 1_500
  end
end
