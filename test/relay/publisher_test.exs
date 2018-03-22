defmodule Relay.PublisherTest.Macros do
  defmacro xds_tests(name_suffix, assertion) do
    Relay.Publisher.discovery_services()
    |> Enum.map(fn xds ->
      quote do
        test(
          "#{unquote(xds)} #{unquote(name_suffix)}",
          %{publisher: publisher},
          do: unquote(assertion).(publisher, unquote(xds))
        )
      end
    end)
  end
end

defmodule Relay.PublisherTest do
  use ExUnit.Case, async: true

  alias Relay.Publisher
  alias Publisher.Resources

  import Relay.PublisherTest.Macros

  setup do
    {:ok, publisher} = start_supervised(Publisher)
    %{publisher: publisher}
  end

  def get_resources(publisher, xds) do
    {:ok, resources} = GenServer.call(publisher, {:_get_resources, xds})
    resources
  end

  xds_tests "subscribe idempotent", fn publisher, xds ->
    assert get_resources(publisher, xds) == %Resources{subscribers: MapSet.new()}

    assert Publisher.subscribe(publisher, xds, self()) == :ok
    assert_receive {^xds, "", []}, 100
    assert get_resources(publisher, xds) == %Resources{subscribers: MapSet.new([self()])}

    assert Publisher.subscribe(publisher, xds, self()) == :ok
    assert_receive {^xds, "", []}, 100
    assert get_resources(publisher, xds) == %Resources{subscribers: MapSet.new([self()])}
  end

  defp assert_subscribe(publisher, xds, version_info \\ "", resources \\ []) do
    assert Publisher.subscribe(publisher, xds, self()) == :ok
    assert_receive {^xds, ^version_info, ^resources}, 100
  end

  xds_tests "unsubscribe idempotent", fn publisher, xds ->
    assert_subscribe(publisher, xds)
    assert get_resources(publisher, xds) == %Resources{subscribers: MapSet.new([self()])}

    assert Publisher.unsubscribe(publisher, xds, self()) == :ok
    assert get_resources(publisher, xds) == %Resources{subscribers: MapSet.new()}

    assert Publisher.unsubscribe(publisher, xds, self()) == :ok
    assert get_resources(publisher, xds) == %Resources{subscribers: MapSet.new()}
  end

  xds_tests "subscribers receive updates", fn publisher, xds ->
    assert_subscribe(publisher, xds)

    resources = [:foo, :bar]
    assert Publisher.update(publisher, xds, "1", resources) == :ok

    assert_receive {^xds, "1", ^resources}, 1_000
  end

  xds_tests "old updates ignored", fn publisher, xds ->
    resources = [:foobar, :baz]
    assert Publisher.update(publisher, xds, "2", resources) == :ok

    assert_subscribe(publisher, xds, "2", resources)

    old_resources = [:foo, :bar]
    assert Publisher.update(publisher, xds, "1", old_resources) == :ok

    # Assert the publisherd resources haven't changed
    assert %Resources{version_info: "2", resources: ^resources} = get_resources(publisher, xds)
    # Assert we don't receive any updates for this xds
    refute_received {^xds, _, _}
  end
end
