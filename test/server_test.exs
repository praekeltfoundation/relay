defmodule Relay.ServerTest do
  use ExUnit.Case, async: true

  alias Relay.Server.ListenerDiscoveryService, as: LDS
  alias Relay.Server.RouteDiscoveryService, as: RDS
  alias Relay.Server.ClusterDiscoveryService, as: CDS
  alias Relay.Server.EndpointDiscoveryService, as: EDS

  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}

  alias Envoy.Api.V2.ListenerDiscoveryService.Stub, as: LDSStub
  alias Envoy.Api.V2.RouteDiscoveryService.Stub, as: RDSStub
  alias Envoy.Api.V2.ClusterDiscoveryService.Stub, as: CDSStub
  alias Envoy.Api.V2.EndpointDiscoveryService.Stub, as: EDSStub

  alias Google.Protobuf.Any

  setup_all do
    TestHelpers.setup_apps([:relay])
  end

  setup do
    TestHelpers.override_log_level(:info)

    servers = [LDS, RDS, CDS, EDS]
    {:ok, pid, port} = GRPC.Server.start(servers, 0)
    {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{port}")

    on_exit fn -> GRPC.Server.stop(servers) end

    %{channel: channel, pid: pid}
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

  test "stream_listeners streams a DiscoveryResponse", %{channel: channel} do
    stream = channel |> LDSStub.stream_listeners()
    type_url = LDS.type_url

    task = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new(), end_stream: true)
    end)

    result_enum = GRPC.Stub.recv(stream)
    Task.await(task)

    assert [response] = Enum.to_list(result_enum)
    assert %DiscoveryResponse{type_url: ^type_url, resources: resources} = response

    assert length(resources) > 0
    resources |> Enum.each(fn(resource) ->
      assert %Any{type_url: ^type_url} = resource
    end)
  end

  test "stream_clusters streams a DiscoveryResponse", %{channel: channel} do
    stream = channel |> CDSStub.stream_clusters()
    type_url = CDS.type_url

    task = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new(), end_stream: true)
    end)

    result_enum = GRPC.Stub.recv(stream)
    Task.await(task)

    assert [response] = Enum.to_list(result_enum)
    assert %DiscoveryResponse{type_url: ^type_url, resources: resources} = response

    assert length(resources) > 0
    resources |> Enum.each(fn(resource) ->
      assert %Any{type_url: ^type_url} = resource
    end)
  end

  test "stream_routes streams a DiscoveryResponse", %{channel: channel} do
    stream = channel |> RDSStub.stream_routes()
    type_url = RDS.type_url

    task = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new(), end_stream: true)
    end)

    result_enum = GRPC.Stub.recv(stream)
    Task.await(task)

    assert [response] = Enum.to_list(result_enum)
    assert %DiscoveryResponse{type_url: ^type_url, resources: resources} = response

    # TODO: Return some resources
    assert resources == []
  end

  test "stream_endpoints streams a DiscoveryResponse", %{channel: channel} do
    stream = channel |> EDSStub.stream_endpoints()
    type_url = EDS.type_url

    task = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new(), end_stream: true)
    end)

    result_enum = GRPC.Stub.recv(stream)
    Task.await(task)

    assert [response] = Enum.to_list(result_enum)
    assert %DiscoveryResponse{type_url: ^type_url, resources: resources} = response

    # TODO: Return some resources
    assert resources == []
  end
end
