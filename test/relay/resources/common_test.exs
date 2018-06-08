defmodule Relay.Resources.CommonTest do
  use ExUnit.Case, async: false

  alias Relay.Resources.Common

  alias Envoy.Api.V2.Core.{ApiConfigSource, ConfigSource, GrpcService}
  alias Google.Protobuf.Duration

  describe "api_config_source/1" do
    defp assert_config_source(config_source, target_uri, stat_prefix) do
      assert %ConfigSource{
               config_source_specifier:
                 {:api_config_source,
                  %ApiConfigSource{
                    cluster_names: [],
                    grpc_services: [
                      %GrpcService{
                        target_specifier:
                          {:google_grpc,
                           %GrpcService.GoogleGrpc{
                             target_uri: ^target_uri,
                             stat_prefix: ^stat_prefix
                           }}
                      }
                    ]
                  }}
             } = config_source
    end

    test "default config" do
      assert_config_source(Common.api_config_source(), "127.0.0.1:5000", "xds_cluster")
    end

    test "override config" do
      grpc_config = [target_uri: "10.1.1.1:1337", stat_prefix: "numbers"]
      TestHelpers.put_env(:relay, :envoy, grpc: grpc_config)

      assert_config_source(Common.api_config_source(), "10.1.1.1:1337", "numbers")
    end
  end

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
