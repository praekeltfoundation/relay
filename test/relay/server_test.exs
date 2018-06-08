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

  defp assert_unimplemented(channel, req_fun) do
    {:error, reply} = req_fun.(channel, DiscoveryRequest.new())

    assert reply == %GRPC.RPCError{
             status: GRPC.Status.unimplemented(),
             message: "not implemented"
           }
  end

  test "fetch_listeners unimplemented", %{channel: channel} do
    assert_unimplemented(channel, &LDSStub.fetch_listeners/2)
  end

  test "fetch_routes unimplemented", %{channel: channel} do
    assert_unimplemented(channel, &RDSStub.fetch_routes/2)
  end

  test "fetch_clusters unimplemented", %{channel: channel} do
    assert_unimplemented(channel, &CDSStub.fetch_clusters/2)
  end

  test "fetch_endpoints unimplemented", %{channel: channel} do
    assert_unimplemented(channel, &EDSStub.fetch_endpoints/2)
  end

  defp assert_streams_responses(stream, server, example_resource) do
    type_url = server.type_url()
    request = DiscoveryRequest.new(type_url: type_url)

    # Send the first request
    GRPC.Stub.send_request(stream, request)
    assert {:ok, result_enum} = GRPC.Stub.recv(stream)

    # We should receive a response right away...
    assert_from_stream(result_enum, type_url, "", [])

    # Make the second request, this requires something to be updated in the publisher
    GRPC.Stub.send_request(stream, request, end_stream: true)

    # Once we update something in the publisher it should be returned in a response
    Publisher.update(Publisher, server.xds(), "1", [example_resource])

    assert_from_stream(result_enum, type_url, "1", [example_resource])
  end

  defp assert_from_stream(resp_stream, type_url, version_info, resources) do
    assert [{:ok, response}] = Enum.take(resp_stream, 1)

    assert %DiscoveryResponse{
             type_url: ^type_url,
             version_info: ^version_info,
             resources: received_resources
           } = response

    assert length(resources) == length(received_resources)

    received_resources
    |> Enum.zip(resources)
    |> Enum.map(fn {rec, exp} ->
      assert rec.type_url == type_url
      assert exp.__struct__.decode(rec.value) == exp
    end)
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

  test "stream_endpoints filters data in DiscoveryResponses", %{channel: channel} do
    type_url = EDS.type_url()

    stream = channel |> EDSStub.stream_endpoints()
    request = DiscoveryRequest.new(type_url: type_url, resource_names: ["test1"])

    # Send the first request
    GRPC.Stub.send_request(stream, request)
    assert {:ok, result_enum} = GRPC.Stub.recv(stream)

    # We should receive an empty response right away...
    assert_from_stream(result_enum, type_url, "", [])

    # Make the second request, this requires something to be updated in the publisher
    GRPC.Stub.send_request(stream, request, end_stream: true)

    test1 = ClusterLoadAssignment.new(cluster_name: "test1")
    test2 = ClusterLoadAssignment.new(cluster_name: "test2")

    # Once we update something in the publisher it should be returned in a response
    Publisher.update(Publisher, :eds, "1", [test1, test2])

    assert_from_stream(result_enum, type_url, "1", [test1])
  end

  describe "process_macro_opts/1" do
    # These tests exist mostly to provide runtime coverage of the function,
    # which is necessary because it's otherwise only called at compile-time
    # during macro expansion.

    alias Relay.Server.Macros

    test "minimal input" do
      assert Macros.process_macro_opts(resources: :things) == %{
               stream_func: :stream_things,
               fetch_func: :fetch_things,
               name_field: :name
             }
    end

    test "override name_field" do
      assert Macros.process_macro_opts(resources: :things, name_field: :moniker) == %{
               stream_func: :stream_things,
               fetch_func: :fetch_things,
               name_field: :moniker
             }
    end
  end
end
