defmodule Relay.SupervisorTest do
  use ExUnit.Case

  alias Relay.{Supervisor, Demo, Demo2, Store}

  alias Envoy.Api.V2.{DiscoveryRequest, DiscoveryResponse}
  alias Envoy.Api.V2.ListenerDiscoveryService.Stub, as: LDSStub
  alias Envoy.Api.V2.Listener

  import ExUnit.CaptureLog

  @port 12345

  setup do
    TestHelpers.setup_apps([:grpc])
    TestHelpers.override_log_level(:warn)
    Application.put_env(:grpc, :start_server, true)

    {:ok, sup} = start_supervised({Supervisor, {@port}})
    %{supervisor: sup}
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

  test "when the Store exits everything is restarted" do
    Process.flag(:trap_exit, true)

    # Monitor the server and demo
    server_ref = Process.whereis(GRPC.Server.Supervisor) |> Process.monitor()
    demo_ref = Process.whereis(Demo2) |> Process.monitor()

    # Exit the Store process
    Process.whereis(Store) |> Process.exit(:kill)

    # The server and demo quit
    assert_receive {:DOWN, ^server_ref, :process, _, :shutdown}, 1_000
    assert_receive {:DOWN, ^demo_ref, :process, _, :shutdown}, 1_000

    # Wait for the processes to restart :-/
    Process.sleep(50)

    # Things still work as everything has been restarted
    assert_example_response()
  end

  test "when the GRPC supervisor exits it is restarted" do
    Process.flag(:trap_exit, true)

    store_pid = Process.whereis(Store)
    demo_pid = Process.whereis(Demo2)

    grpc_pid = Process.whereis(GRPC.Server.Supervisor)
    grpc_ref = Process.monitor(grpc_pid)

    # Capture the error logged when we kill the supervisor
    assert capture_log(fn() ->
      # Exit the GRPC process
      grpc_pid |> Process.exit(:kill)

      # Check the GRPC supervisor quit
      assert_receive {:DOWN, ^grpc_ref, :process, _, :killed}, 1_000

      # Other things still happily running
      assert Process.alive?(store_pid)
      assert Process.alive?(demo_pid)

      # Wait for the processes to restart :-/
      Process.sleep(50)
    end) =~ ~r/\[error\] GenServer #PID<\S*> terminating\n\*\* \(stop\) killed/

    # Everything else still works because it's all running again
    assert_example_response()
  end

  test "when the Demo exits it is restarted" do
    Process.flag(:trap_exit, true)

    store_pid = Process.whereis(Store)
    grpc_pid = Process.whereis(GRPC.Server.Supervisor)

    demo_pid = Process.whereis(Demo2)
    demo_ref = Process.monitor(demo_pid)

    # Exit the demo process
    demo_pid |> Process.exit(:kill)

    # Check the demo quit
    assert_receive {:DOWN, ^demo_ref, :process, _, :killed}, 1_000

    # Other things still happily running
    assert Process.alive?(store_pid)
    assert Process.alive?(grpc_pid)

    # Everything else still works because the state is still available
    assert_example_response()
  end
end
