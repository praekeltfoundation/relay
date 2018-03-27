defmodule RelayTest do
  use ExUnit.Case

  alias Relay.{Demo, Publisher, Resources}

  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}
  alias Envoy.Api.V2.ClusterDiscoveryService.Stub, as: CDSStub
  alias Envoy.Api.V2.ListenerDiscoveryService.Stub, as: LDSStub
  alias Envoy.Api.V2.{Cluster, Listener}

  @port 12345

  setup do
    TestHelpers.override_log_level(:warn)
    TestHelpers.put_env(:grpc, :start_server, true)

    listen = Application.get_env(:relay, :listen) |> Keyword.put(:port, @port)
    TestHelpers.put_env(:relay, :listen, listen, persistent: true)
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

  defp assert_cds_request_response(streams, res_enums, version_info, clusters) do
    do_discovery_request(streams[:cds])
    assert_cds_response(res_enums, version_info, clusters)
  end

  defp assert_lds_request_response(streams, res_enums, version_info, clusters) do
    do_discovery_request(streams[:lds])
    assert_lds_response(res_enums, version_info, clusters)
  end

  defp assert_cds_response(res_enums, version_info, clusters) do
    assert [{:ok, response}] = Enum.take(res_enums[:cds], 1)
    assert %DiscoveryResponse{version_info: ^version_info, resources: resources} = response

    assert resources |> Enum.map(fn any_res -> Cluster.decode(any_res.value) end) == clusters
  end

  defp assert_lds_response(res_enums, version_info, listeners) do
    assert [{:ok, response}] = Enum.take(res_enums[:lds], 1)
    assert %DiscoveryResponse{version_info: ^version_info, resources: resources} = response

    assert resources |> Enum.map(fn any_res -> Listener.decode(any_res.value) end) == listeners
  end

  defp demo_clusters, do: Demo.Marathon.app_endpoints() |> Resources.CDS.clusters()
  defp demo_listeners, do: Demo.Certs.sni_certs() |> Resources.LDS.listeners()

  test "starting the application starts everything" do
    procs = [
      GRPC.Server.Supervisor,
      Relay.Supervisor,
      Publisher,
      Resources,
      Demo.Certs,
      Demo.Marathon
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

    assert_cds_response(res_enums, "1", demo_clusters())
    assert_lds_response(res_enums, "1", demo_listeners())
  end

  test "demo app sends multiple updates" do
    :ok = TestHelpers.setup_apps([:relay])

    # The Demo app sends scheduled updates every second, with ad-hoc updates in
    # between if desired
    t0 = Time.utc_now()
    # Initial update
    streams = stream_xds()
    res_enums = recv_xds(streams)
    assert_cds_response(res_enums, "1", demo_clusters())
    assert_lds_response(res_enums, "1", demo_listeners())

    # Ad-hoc updates
    Demo.Marathon.update_state()
    assert_cds_request_response(streams, res_enums, "2", demo_clusters())
    Demo.Certs.update_state()
    assert_lds_request_response(streams, res_enums, "2", demo_listeners())
    Demo.Marathon.update_state()
    assert_cds_request_response(streams, res_enums, "3", demo_clusters())
    t1 = Time.utc_now()
    assert Time.diff(t1, t0, :milliseconds) < 1_000

    # Scheduled update
    assert_cds_request_response(streams, res_enums, "4", demo_clusters())
    assert_lds_request_response(streams, res_enums, "3", demo_listeners())
    t2 = Time.utc_now()
    assert Time.diff(t2, t0, :milliseconds) < 1_500
  end
end
