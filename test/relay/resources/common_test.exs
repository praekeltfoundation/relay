defmodule Relay.Resources.CommonTest do
  use ExUnit.Case, async: true

  alias Relay.Resources.Common

  alias Google.Protobuf.Duration

  describe "truncate_obj_name/1" do
    test "long names truncated from beginning" do
      TestHelpers.put_env(:relay, :envoy, max_obj_name_length: 10)

      assert Common.truncate_obj_name("helloworldmynameis") == "[...]ameis"
    end

    test "short names unchanged" do
      TestHelpers.put_env(:relay, :envoy, max_obj_name_length: 10)

      assert Common.truncate_obj_name("hello") == "hello"
    end
  end

  describe "duration/1" do
    test "positive duration" do
      assert Common.duration(500) == %Duration{seconds: 0, nanos: 500_000_000}
      assert Common.duration(1_000) == %Duration{seconds: 1, nanos: 0}
      assert Common.duration(1_500) == %Duration{seconds: 1, nanos: 500_000_000}
    end

    test "negative duration" do
      assert Common.duration(-500) == %Duration{seconds: 0, nanos: -500_000_000}
      # "a non-zero value for the nanos field must be of the same sign as the seconds field"
      assert Common.duration(-1_000) == %Duration{seconds: -1, nanos: 0}
      assert Common.duration(-1_500) == %Duration{seconds: -1, nanos: -500_000_000}
    end

    test "zero duration" do
      assert Common.duration(0) == %Duration{seconds: 0, nanos: 0}
    end
  end
end
