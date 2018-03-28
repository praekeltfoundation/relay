defmodule Relay.Resources.CDSTest do
  use ExUnit.Case, async: true

  alias Relay.Resources.{AppEndpoint, CDS}

  alias Envoy.Api.V2.Cluster
  alias Envoy.Api.V2.Core.ConfigSource
  alias Google.Protobuf.Duration

  @eds_type Cluster.DiscoveryType.value(:EDS)

  @simple_app_endpoint %AppEndpoint{
    name: "/mc2_0",
    cluster_opts: []
  }

  test "simple cluster" do
    assert [cluster] = CDS.clusters([@simple_app_endpoint])

    assert %Cluster{
             name: "/mc2_0",
             type: @eds_type,
             eds_cluster_config: %Cluster.EdsClusterConfig{
               eds_config: %ConfigSource{},
               service_name: "/mc2_0"
             },
             connect_timeout: %Duration{seconds: 5}
           } = cluster

    assert Protobuf.Validator.valid?(cluster)
  end

  test "cluster with options" do
    connect_timeout = Duration.new(seconds: 10)
    lb_policy = Cluster.LbPolicy.value(:MAGLEV)

    app_endpoint = %AppEndpoint{
      @simple_app_endpoint
      | cluster_opts: [
          connect_timeout: connect_timeout,
          lb_policy: lb_policy
        ]
    }

    assert [cluster] = CDS.clusters([app_endpoint])

    assert %Cluster{
             name: "/mc2_0",
             type: @eds_type,
             eds_cluster_config: %Cluster.EdsClusterConfig{
               eds_config: %ConfigSource{},
               service_name: "/mc2_0"
             },
             connect_timeout: ^connect_timeout,
             lb_policy: ^lb_policy
           } = cluster

    assert Protobuf.Validator.valid?(cluster)
  end

  test "cluster with long name" do
    app_endpoint = %AppEndpoint{
      @simple_app_endpoint
      | name: "/organisation/my_long_group_name/subgroup3456/application2934_0"
    }

    assert [cluster] = CDS.clusters([app_endpoint])

    assert %Cluster{
             name: "[...]ation/my_long_group_name/subgroup3456/application2934_0"
           } = cluster

    assert Protobuf.Validator.valid?(cluster)
  end
end
