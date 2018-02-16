defmodule RelayTest do
  use ExUnit.Case

  alias Relay.{Demo, Store}

  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}
  alias Envoy.Api.V2.ListenerDiscoveryService.Stub, as: LDSStub
  alias Envoy.Api.V2.Listener

  @port 12345

  setup do
    TestHelpers.override_log_level(:warn)
    Application.put_env(:grpc, :start_server, true)
    Application.put_env(:relay, :port, @port)
  end

  defp assert_example_response do
    assert_lds_response("1", Demo.listeners())
  end

  defp assert_lds_response(version_info, listeners) do
    {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{@port}")
    stream = channel |> LDSStub.stream_listeners()
    task = Task.async(fn ->
      GRPC.Stub.stream_send(stream, DiscoveryRequest.new(), end_stream: true)
    end)

    result_enum = GRPC.Stub.recv(stream)
    Task.await(task)

    assert [response] = Enum.to_list(result_enum)
    assert %DiscoveryResponse{version_info: ^version_info, resources: resources} = response

    assert resources |> Enum.map(fn any_res -> Listener.decode(any_res.value) end) == listeners
  end

  test "starting the application starts everything" do
    procs = [GRPC.Server.Supervisor, Relay.Supervisor, Store, Demo]

    # The various processes aren't running before we start the application
    procs |> Enum.each(fn(id) ->
      assert Process.whereis(id) == nil
    end)

    :ok = TestHelpers.setup_apps([:relay])

    # The various processes are running after we start the application
    procs |> Enum.each(fn(id) ->
      assert Process.alive?(Process.whereis(id))
    end)

    assert_example_response()
  end
end
