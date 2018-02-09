defmodule Relay.ServerTest do
  use ExUnit.Case, async: true

  alias Relay.Server.ListenerDiscoveryService, as: Lds
  alias Relay.Server.RouteDiscoveryService, as: Rds
  alias Relay.Server.ClusterDiscoveryService, as: Cds
  alias Relay.Server.EndpointDiscoveryService, as: Eds

  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}

  alias Envoy.Api.V2.ListenerDiscoveryService.Stub, as: LdsStub
  alias Envoy.Api.V2.RouteDiscoveryService.Stub, as: RdsStub
  alias Envoy.Api.V2.ClusterDiscoveryService.Stub, as: CdsStub
  alias Envoy.Api.V2.EndpointDiscoveryService.Stub, as: EdsStub

  setup do
    servers = [Lds, Rds, Cds, Eds]
    {:ok, pid, port} = GRPC.Server.start(servers, 0)
    {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{port}")

    on_exit fn -> GRPC.Server.stop(servers) end

    %{channel: channel, pid: pid}
  end

  test "fetch_listeners unimplemented", %{channel: channel} do
    {:error, reply} = channel |> LdsStub.fetch_listeners(DiscoveryRequest.new())
    assert reply == %GRPC.RPCError{
      status: GRPC.Status.unimplemented(), message: "not implemented"}
  end

  test "fetch_routes unimplemented", %{channel: channel} do
    {:error, reply} = channel |> RdsStub.fetch_routes(DiscoveryRequest.new())
    assert reply == %GRPC.RPCError{
      status: GRPC.Status.unimplemented(), message: "not implemented"}
  end

  test "fetch_clusters unimplemented", %{channel: channel} do
    {:error, reply} = channel |> CdsStub.fetch_clusters(DiscoveryRequest.new())
    assert reply == %GRPC.RPCError{
      status: GRPC.Status.unimplemented(), message: "not implemented"}
  end

  test "fetch_endpoints unimplemented", %{channel: channel} do
    {:error, reply} = channel |> EdsStub.fetch_endpoints(DiscoveryRequest.new())
    assert reply == %GRPC.RPCError{
      status: GRPC.Status.unimplemented(), message: "not implemented"}
  end
end
