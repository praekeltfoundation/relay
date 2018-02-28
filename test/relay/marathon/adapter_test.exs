defmodule Relay.Marathon.AdapterTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon
  alias Marathon.Adapter

  alias Envoy.Api.V2.Cluster
  alias Envoy.Api.V2.Core.{ApiConfigSource, ConfigSource}

  @test_app %Marathon.App{
    id: "/mc2",
    labels: %{
      "HAPROXY_0_REDIRECT_TO_HTTPS" => "true",
      "HAPROXY_0_VHOST" => "mc2.example.org",
      "HAPROXY_GROUP" => "external",
      "MARATHON_ACME_0_DOMAIN" => "mc2.example.org"
    },
    networking_mode: :"container/bridge",
    ports_list: [80],
    version: "2017-11-08T15:06:31.066Z"
  }

  @test_config_source ConfigSource.new(
                        config_source_specifier:
                          {:api_config_source,
                           ApiConfigSource.new(
                             api_type: ApiConfigSource.ApiType.value(:GRPC),
                             cluster_names: ["xds_cluster"]
                           )}
                      )

  describe "truncate_name/2" do
    test "long names truncated from beginning" do
      assert Adapter.truncate_name("helloworldmynameis", 10) == "[...]ameis"
    end

    test "short names unchanged" do
      assert Adapter.truncate_name("hello", 10) == "hello"
    end

    test "max_size must be larger than the prefix length" do
      assert_raise ArgumentError, "`max_size` must be larger than the prefix length", fn ->
        Adapter.truncate_name("hello", 3)
      end
    end
  end

  describe "app_port_cluster/4" do
    test "simple cluster" do
      eds_type = Cluster.DiscoveryType.value(:EDS)
      cluster = Adapter.app_port_cluster(@test_app, 0, @test_config_source)

      assert %Cluster{
               name: "/mc2_0",
               type: ^eds_type,
               eds_cluster_config: %Cluster.EdsClusterConfig{
                 eds_config: @test_config_source,
                 service_name: "/mc2_0"
               }
             } = cluster

      assert Protobuf.Validator.valid?(cluster)
    end

    test "cluster with options" do
      alias Google.Protobuf.Duration

      eds_type = Cluster.DiscoveryType.value(:EDS)
      connect_timeout = Duration.new(seconds: 10)
      lb_policy = Cluster.LbPolicy.value(:MAGLEV)

      cluster =
        Adapter.app_port_cluster(
          @test_app,
          0,
          @test_config_source,
          connect_timeout: connect_timeout,
          lb_policy: lb_policy
        )

      assert %Cluster{
               name: "/mc2_0",
               type: ^eds_type,
               eds_cluster_config: %Cluster.EdsClusterConfig{
                 eds_config: @test_config_source,
                 service_name: "/mc2_0"
               },
               connect_timeout: ^connect_timeout,
               lb_policy: ^lb_policy
             } = cluster

      assert Protobuf.Validator.valid?(cluster)
    end

    test "cluster with long name" do
      app = %{@test_app | id: "/organisation/my_long_group_name/subgroup3456/application2934"}

      assert %Cluster{name: "[...]ation/my_long_group_name/subgroup3456/application2934_0"} =
               Adapter.app_port_cluster(app, 0, @test_config_source)
    end

    test "custom max_obj_name_length" do
      app = %{@test_app | id: "/myslightlylongname"}
      cluster = Adapter.app_port_cluster(app, 0, @test_config_source, max_obj_name_length: 10)

      assert %Cluster{name: "[...]ame_0"} = cluster
      assert Protobuf.Validator.valid?(cluster)
    end
  end
end
