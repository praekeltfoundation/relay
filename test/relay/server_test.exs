defmodule Relay.ServerTest do
  use ExUnit.Case

  alias Relay.Server.ListenerDiscoveryService, as: LDS
  alias Relay.Server.RouteDiscoveryService, as: RDS
  alias Relay.Server.ClusterDiscoveryService, as: CDS
  alias Relay.Server.EndpointDiscoveryService, as: EDS

  alias Relay.Publisher

  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}

  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment, Listener, RouteConfiguration}

  alias Envoy.Api.V2.ListenerDiscoveryService.Stub, as: LDSStub
  alias Envoy.Api.V2.RouteDiscoveryService.Stub, as: RDSStub
  alias Envoy.Api.V2.ClusterDiscoveryService.Stub, as: CDSStub
  alias Envoy.Api.V2.EndpointDiscoveryService.Stub, as: EDSStub

  setup do
    TestHelpers.setup_apps([:grpc])
    TestHelpers.override_log_level(:warn)

    {:ok, publisher} = start_supervised({Publisher, [name: Publisher]})

    servers = [LDS, RDS, CDS, EDS]
    {:ok, pid, port} = GRPC.Server.start(servers, 0)
    {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{port}")

    on_exit(fn -> GRPC.Server.stop(servers) end)

    %{channel: channel, pid: pid, publisher: publisher}
  end

  test "fetch_listeners unimplemented", %{channel: channel} do
    {:error, reply} = channel |> LDSStub.fetch_listeners(DiscoveryRequest.new())

    assert reply == %GRPC.RPCError{
             status: GRPC.Status.unimplemented(),
             message: "not implemented"
           }
  end

  test "fetch_routes unimplemented", %{channel: channel} do
    {:error, reply} = channel |> RDSStub.fetch_routes(DiscoveryRequest.new())

    assert reply == %GRPC.RPCError{
             status: GRPC.Status.unimplemented(),
             message: "not implemented"
           }
  end

  test "fetch_clusters unimplemented", %{channel: channel} do
    {:error, reply} = channel |> CDSStub.fetch_clusters(DiscoveryRequest.new())

    assert reply == %GRPC.RPCError{
             status: GRPC.Status.unimplemented(),
             message: "not implemented"
           }
  end

  test "fetch_endpoints unimplemented", %{channel: channel} do
    {:error, reply} = channel |> EDSStub.fetch_endpoints(DiscoveryRequest.new())

    assert reply == %GRPC.RPCError{
             status: GRPC.Status.unimplemented(),
             message: "not implemented"
           }
  end

  defp assert_streams_responses(stream, server, example_resource) do
    xds = server.xds()
    type_url = server.type_url()
    request = DiscoveryRequest.new(type_url: type_url)

    # Send the first request
    task1 = Task.async(fn -> GRPC.Stub.send_request(stream, request) end)

    assert {:ok, result_enum} = GRPC.Stub.recv(stream)
    Task.await(task1)

    # We should receive a response right away...
    assert [{:ok, response1}] = Enum.take(result_enum, 1)
    assert %DiscoveryResponse{type_url: ^type_url, version_info: "", resources: []} = response1

    # Make the second request, this requires something to be updated in the publisher
    task2 =
      Task.async(fn ->
        GRPC.Stub.stream_send(stream, request, end_stream: true)
      end)

    # Once we update something in the publisher it should be returned in a response
    Publisher.update(Publisher, xds, "1", [example_resource])

    Task.await(task2)

    assert [{:ok, response2}] = Enum.to_list(result_enum)

    assert %DiscoveryResponse{type_url: ^type_url, version_info: "1", resources: [any_resource]} =
             response2

    assert any_resource.type_url == type_url
    assert example_resource.__struct__.decode(any_resource.value) == example_resource
  end

  test "stream_listeners streams DiscoveryResponses", %{channel: channel} do
    stream = channel |> LDSStub.stream_listeners()
    assert_streams_responses(stream, LDS, Listener.new(name: "test"))
  end

  test "stream_clusters streams DiscoveryResponses", %{channel: channel} do
    stream = channel |> CDSStub.stream_clusters()
    assert_streams_responses(stream, CDS, Cluster.new(name: "test"))
  end

  test "stream_routes streams DiscoveryResponses", %{channel: channel} do
    stream = channel |> RDSStub.stream_routes()
    assert_streams_responses(stream, RDS, RouteConfiguration.new(name: "test"))
  end

  test "stream_endpoints streams DiscoveryResponses", %{channel: channel} do
    stream = channel |> EDSStub.stream_endpoints()
    assert_streams_responses(stream, EDS, ClusterLoadAssignment.new(cluster_name: "test"))
  end
end
