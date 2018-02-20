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

  defp stream_lds() do
    {:ok, channel} = GRPC.Stub.connect("127.0.0.1:#{@port}")
    channel |> LDSStub.stream_listeners()
  end

  defp assert_lds_response(stream, version_info, listeners) do
    result_stream = GRPC.Stub.recv(stream)
    GRPC.Stub.stream_send(stream, DiscoveryRequest.new())

    assert [response] = Enum.take(result_stream, 1)
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

    stream = stream_lds()
    assert_lds_response(stream, "1", Demo.listeners())
  end

  test "demo app sends multiple updates" do
    :ok = TestHelpers.setup_apps([:relay])

    # The Demo app sends scheduled updates every second, with ad-hoc updates in
    # between if desired
    t0 = Time.utc_now()
    # Initial update
    stream = stream_lds()
    assert_lds_response(stream, "1", Demo.listeners())
    # Ad-hoc update
    Demo.update_state()
    assert_lds_response(stream, "2", Demo.listeners())
    t1 = Time.utc_now()
    assert Time.diff(t1, t0, :milliseconds) < 1_000
    # Scheduled update
    assert_lds_response(stream, "3", Demo.listeners())
    t2 = Time.utc_now()
    assert Time.diff(t2, t0, :milliseconds) < 1_500
  end
end
