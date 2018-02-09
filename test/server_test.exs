defmodule Relay.ServerTest do
  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}

  defmodule ListenerDiscoveryServiceTest do
    use ExUnit.Case, async: true

    alias Relay.Server.ListenerDiscoveryService
    alias Envoy.Api.V2.ListenerDiscoveryService.Stub

    setup do
      {:ok, pid, port} = GRPC.Server.start(ListenerDiscoveryService, 0)
      {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{port}")

      on_exit fn -> GRPC.Server.stop(ListenerDiscoveryService) end

      %{channel: channel, pid: pid}
    end

    test "fetch listeners unimplemented", %{channel: channel} do
      request = DiscoveryRequest.new()
      {:error, reply} = channel |> Stub.fetch_listeners(request)

      assert reply == %GRPC.RPCError{
        status: GRPC.Status.unimplemented(),
        message: "not implemented"
      }
    end
  end

  defmodule RouteDiscoveryServiceTest do
    use ExUnit.Case, async: true

    alias Relay.Server.RouteDiscoveryService
    alias Envoy.Api.V2.RouteDiscoveryService.Stub

    setup do
      {:ok, pid, port} = GRPC.Server.start(RouteDiscoveryService, 0)
      {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{port}")

      on_exit fn -> GRPC.Server.stop(RouteDiscoveryService) end

      %{channel: channel, pid: pid}
    end

    test "fetch listeners unimplemented", %{channel: channel} do
      request = DiscoveryRequest.new()
      {:error, reply} = channel |> Stub.fetch_routes(request)

      assert reply == %GRPC.RPCError{
        status: GRPC.Status.unimplemented(),
        message: "not implemented"
      }
    end
  end

  defmodule ClusterDiscoveryServiceTest do
    use ExUnit.Case, async: true

    alias Relay.Server.ClusterDiscoveryService
    alias Envoy.Api.V2.ClusterDiscoveryService.Stub

    setup do
      {:ok, pid, port} = GRPC.Server.start(ClusterDiscoveryService, 0)
      {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{port}")

      on_exit fn -> GRPC.Server.stop(ClusterDiscoveryService) end

      %{channel: channel, pid: pid}
    end

    test "fetch listeners unimplemented", %{channel: channel} do
      request = DiscoveryRequest.new()
      {:error, reply} = channel |> Stub.fetch_clusters(request)

      assert reply == %GRPC.RPCError{
        status: GRPC.Status.unimplemented(),
        message: "not implemented"
      }
    end
  end

  defmodule EndpointDiscoveryServiceTest do
    use ExUnit.Case, async: true

    alias Relay.Server.EndpointDiscoveryService
    alias Envoy.Api.V2.EndpointDiscoveryService.Stub

    setup do
      {:ok, pid, port} = GRPC.Server.start(EndpointDiscoveryService, 0)
      {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{port}")

      on_exit fn -> GRPC.Server.stop(EndpointDiscoveryService) end

      %{channel: channel, pid: pid}
    end

    test "fetch listeners unimplemented", %{channel: channel} do
      request = DiscoveryRequest.new()
      {:error, reply} = channel |> Stub.fetch_endpoints(request)

      assert reply == %GRPC.RPCError{
        status: GRPC.Status.unimplemented(),
        message: "not implemented"
      }
    end
  end
end
