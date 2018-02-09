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

  test "fetch endpoints unimplemented", %{channel: channel} do
    request = DiscoveryRequest.new()
    unimplemented_error = %GRPC.RPCError{
      status: GRPC.Status.unimplemented(),
      message: "not implemented"
    }

    {:error, lds_reply} = channel |> LdsStub.fetch_listeners(request)
    assert lds_reply == unimplemented_error

    {:error, rds_reply} = channel |> RdsStub.fetch_routes(request)
    assert rds_reply == unimplemented_error

    {:error, cds_reply} = channel |> CdsStub.fetch_clusters(request)
    assert cds_reply == unimplemented_error

    {:error, eds_reply} = channel |> EdsStub.fetch_endpoints(request)
    assert eds_reply == unimplemented_error
  end
end
