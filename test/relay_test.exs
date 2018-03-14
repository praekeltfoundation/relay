defmodule RelayTest do
  use ExUnit.Case

  alias Relay.{Demo, Store}

  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}
  alias Envoy.Api.V2.ClusterDiscoveryService.Stub, as: CDSStub
  alias Envoy.Api.V2.ListenerDiscoveryService.Stub, as: LDSStub
  alias Envoy.Api.V2.{Cluster, Listener}

  @port 12345

  setup do
    TestHelpers.override_log_level(:warn)
    Application.put_env(:grpc, :start_server, true)
    Application.put_env(:relay, :port, @port)
  end

  defp stream_xds() do
    {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{@port}")
    %{
      cds: channel |> CDSStub.stream_clusters(),
      lds: channel |> LDSStub.stream_listeners(),
    }
  end

  defp assert_cds_response(streams, version_info, clusters) do
    result_stream = GRPC.Stub.recv(streams[:cds])
    GRPC.Stub.stream_send(streams[:cds], DiscoveryRequest.new())

    assert [response] = Enum.take(result_stream, 1)
    assert %DiscoveryResponse{version_info: ^version_info, resources: resources} = response

    assert resources |> Enum.map(fn any_res -> Cluster.decode(any_res.value) end) == clusters
  end

  defp assert_lds_response(streams, version_info, listeners) do
    result_stream = GRPC.Stub.recv(streams[:lds])
    GRPC.Stub.stream_send(streams[:lds], DiscoveryRequest.new())

    assert [response] = Enum.take(result_stream, 1)
    assert %DiscoveryResponse{version_info: ^version_info, resources: resources} = response

    assert resources |> Enum.map(fn any_res -> Listener.decode(any_res.value) end) == listeners
  end

  test "starting the application starts everything" do
    procs = [GRPC.Server.Supervisor, Relay.Supervisor, Store, Demo.Marathon]

    # The various processes aren't running before we start the application
    procs |> Enum.each(fn(id) ->
      assert Process.whereis(id) == nil
    end)

    :ok = TestHelpers.setup_apps([:relay])

    # The various processes are running after we start the application
    procs |> Enum.each(fn(id) ->
      assert Process.alive?(Process.whereis(id))
    end)

    streams = stream_xds()
    assert_cds_response(streams, "1", Demo.Marathon.clusters())
    assert_lds_response(streams, "1", Demo.Certs.listeners())
  end

  test "demo app sends multiple updates" do
    :ok = TestHelpers.setup_apps([:relay])

    # The Demo app sends scheduled updates every second, with ad-hoc updates in
    # between if desired
    t0 = Time.utc_now()
    # Initial update
    streams = stream_xds()
    assert_cds_response(streams, "1", Demo.Marathon.clusters())
    assert_lds_response(streams, "1", Demo.Certs.listeners())
    # Ad-hoc updates
    Demo.Marathon.update_state()
    assert_cds_response(streams, "2", Demo.Marathon.clusters())
    Demo.Certs.update_state()
    assert_lds_response(streams, "2", Demo.Certs.listeners())
    Demo.Marathon.update_state()
    assert_cds_response(streams, "3", Demo.Marathon.clusters())
    t1 = Time.utc_now()
    assert Time.diff(t1, t0, :milliseconds) < 1_000
    # Scheduled update
    assert_cds_response(streams, "4", Demo.Marathon.clusters())
    assert_lds_response(streams, "3", Demo.Certs.listeners())
    t2 = Time.utc_now()
    assert Time.diff(t2, t0, :milliseconds) < 1_500
  end
end
