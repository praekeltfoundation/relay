defmodule Relay.ServerTest.Macros do
  defmacro server_tests do
    [:listeners, :routers]
  end
end

defmodule Relay.ServerTest do
  use ExUnit.Case

  alias Relay.Server.ListenerDiscoveryService, as: LDS
  alias Relay.Server.RouteDiscoveryService, as: RDS
  alias Relay.Server.ClusterDiscoveryService, as: CDS
  alias Relay.Server.EndpointDiscoveryService, as: EDS

  alias Relay.Store

  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}

  alias Envoy.Api.V2.{Cluster, ClusterLoadAssignment, Listener, RouteConfiguration}

  alias Envoy.Api.V2.ListenerDiscoveryService.Stub, as: LDSStub
  alias Envoy.Api.V2.RouteDiscoveryService.Stub, as: RDSStub
  alias Envoy.Api.V2.ClusterDiscoveryService.Stub, as: CDSStub
  alias Envoy.Api.V2.EndpointDiscoveryService.Stub, as: EDSStub

  setup do
    TestHelpers.override_log_level(:info)

    {:ok, store} = start_supervised({Store, [name: Store]})

    servers = [LDS, RDS, CDS, EDS]
    {:ok, pid, port} = GRPC.Server.start(servers, 0)
    {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{port}")

    on_exit fn -> GRPC.Server.stop(servers) end

    %{channel: channel, pid: pid, store: store}
  end

  test "fetch_listeners unimplemented", %{channel: channel} do
    {:error, reply} = channel |> LDSStub.fetch_listeners(DiscoveryRequest.new())
    assert reply == %GRPC.RPCError{
      status: GRPC.Status.unimplemented(), message: "not implemented"}
  end

  test "fetch_routes unimplemented", %{channel: channel} do
    {:error, reply} = channel |> RDSStub.fetch_routes(DiscoveryRequest.new())
    assert reply == %GRPC.RPCError{
      status: GRPC.Status.unimplemented(), message: "not implemented"}
  end

  test "fetch_clusters unimplemented", %{channel: channel} do
    {:error, reply} = channel |> CDSStub.fetch_clusters(DiscoveryRequest.new())
    assert reply == %GRPC.RPCError{
      status: GRPC.Status.unimplemented(), message: "not implemented"}
  end

  test "fetch_endpoints unimplemented", %{channel: channel} do
    {:error, reply} = channel |> EDSStub.fetch_endpoints(DiscoveryRequest.new())
    assert reply == %GRPC.RPCError{
      status: GRPC.Status.unimplemented(), message: "not implemented"}
  end

  test "stream_listeners streams a DiscoveryResponse", %{channel: channel, store: store} do
    stream = channel |> LDSStub.stream_listeners()
    type_url = LDS.type_url

    # Send the first request
    task1 = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new())
    end)

    result_enum = GRPC.Stub.recv(stream)
    Task.await(task1)

    # We should receive a response right away...
    assert [response1] = Enum.take(result_enum, 1)
    assert %DiscoveryResponse{type_url: ^type_url, version_info: "", resources: []} = response1

    # Make the second request, this requires something to be updated in the store
    task2 = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new(), end_stream: true)
    end)

    # Once we update something in the store it should be returned in a response
    resources = [Listener.new(name: "test")]
    Store.update(store, LDS.xds(), "1", resources)

    Task.await(task2)

    assert [response2] = Enum.to_list(result_enum)
    assert %DiscoveryResponse{
      type_url: ^type_url, version_info: "1", resources: [any_resource]} = response2

    assert any_resource.type_url == type_url
    assert [Listener.decode(any_resource.value)] == resources
  end

  test "stream_clusters streams DiscoveryResponses", %{channel: channel, store: store} do
    stream = channel |> CDSStub.stream_clusters()
    type_url = CDS.type_url

    # Send the first request
    task1 = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new())
    end)

    result_enum = GRPC.Stub.recv(stream)
    Task.await(task1)

    # We should receive a response right away...
    assert [response1] = Enum.take(result_enum, 1)
    assert %DiscoveryResponse{type_url: ^type_url, version_info: "", resources: []} = response1

    # Make the second request, this requires something to be updated in the store
    task2 = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new(), end_stream: true)
    end)

    # Once we update something in the store it should be returned in a response
    resources = [Cluster.new(name: "test")]
    Store.update(store, CDS.xds(), "1", resources)

    Task.await(task2)

    assert [response2] = Enum.to_list(result_enum)
    assert %DiscoveryResponse{
      type_url: ^type_url, version_info: "1", resources: [any_resource]} = response2

    assert any_resource.type_url == type_url
    assert [Cluster.decode(any_resource.value)] == resources
  end

  test "stream_routes streams DiscoveryResponses", %{channel: channel, store: store} do
    stream = channel |> RDSStub.stream_routes()
    type_url = RDS.type_url

    # Send the first request
    task1 = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new())
    end)

    result_enum = GRPC.Stub.recv(stream)
    Task.await(task1)

    # We should receive a response right away...
    assert [response1] = Enum.take(result_enum, 1)
    assert %DiscoveryResponse{type_url: ^type_url, version_info: "", resources: []} = response1

    # Make the second request, this requires something to be updated in the store
    task2 = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new(), end_stream: true)
    end)

    # Once we update something in the store it should be returned in a response
    resources = [RouteConfiguration.new(name: "test")]
    Store.update(store, RDS.xds(), "1", resources)

    Task.await(task2)

    assert [response2] = Enum.to_list(result_enum)
    assert %DiscoveryResponse{
      type_url: ^type_url, version_info: "1", resources: [any_resource]} = response2

    assert any_resource.type_url == type_url
    assert [RouteConfiguration.decode(any_resource.value)] == resources
  end

  test "stream_endpoints streams DiscoveryResponses", %{channel: channel, store: store} do
    stream = channel |> EDSStub.stream_endpoints()
    type_url = EDS.type_url

    # Send the first request
    task1 = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new())
    end)

    result_enum = GRPC.Stub.recv(stream)
    Task.await(task1)

    # We should receive a response right away...
    assert [response1] = Enum.take(result_enum, 1)
    assert %DiscoveryResponse{type_url: ^type_url, version_info: "", resources: []} = response1

    # Make the second request, this requires something to be updated in the store
    task2 = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new(), end_stream: true)
    end)

    # Once we update something in the store it should be returned in a response
    resources = [ClusterLoadAssignment.new(cluster_name: "test")]
    Store.update(store, EDS.xds(), "1", resources)

    Task.await(task2)

    assert [response2] = Enum.to_list(result_enum)
    assert %DiscoveryResponse{
      type_url: ^type_url, version_info: "1", resources: [any_resource]} = response2

    assert any_resource.type_url == type_url
    assert [ClusterLoadAssignment.decode(any_resource.value)] == resources
  end
end
