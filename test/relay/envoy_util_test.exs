defmodule Relay.EnvoyUtilTest do
  use ExUnit.Case, async: true

  alias Relay.EnvoyUtil

  describe "truncate_obj_name/1" do
    test "long names truncated from beginning" do
      TestHelpers.put_env(:relay, :envoy, [max_obj_name_length: 10])

      assert EnvoyUtil.truncate_obj_name("helloworldmynameis") == "[...]ameis"
    end

    test "short names unchanged" do
      TestHelpers.put_env(:relay, :envoy, [max_obj_name_length: 10])

      assert EnvoyUtil.truncate_obj_name("hello") == "hello"
    end
  end
end
