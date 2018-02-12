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
end
