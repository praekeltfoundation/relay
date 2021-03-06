defmodule Relay.Resources.CDSTest do
  use ExUnit.Case, async: true

  alias Relay.Resources.{AppEndpoint, CDS}

  alias Envoy.Api.V2.Cluster
  alias Envoy.Api.V2.Core.ConfigSource

  @eds_type Cluster.DiscoveryType.value(:EDS)

  @simple_app_endpoint %AppEndpoint{
    name: "/mc2_0",
    cluster_opts: []
  }

  test "simple cluster" do
    assert [cluster] = CDS.clusters([@simple_app_endpoint])

    connect_timeout = CDS.default_connect_timeout()

    assert %Cluster{
             name: "/mc2_0",
             type: @eds_type,
             eds_cluster_config: %Cluster.EdsClusterConfig{
               eds_config: %ConfigSource{},
               service_name: "/mc2_0"
             },
             connect_timeout: ^connect_timeout
           } = cluster

    assert Protobuf.Validator.valid?(cluster)
  end

  test "override default connect timeout" do
    alias Google.Protobuf.Duration
    connect_timeout = Duration.new(seconds: 42)

    app_endpoint = %AppEndpoint{
      @simple_app_endpoint
      | cluster_opts: [connect_timeout: Duration.new(seconds: 42)]
    }

    assert [cluster] = CDS.clusters([app_endpoint])

    assert %Cluster{connect_timeout: ^connect_timeout} = cluster

    assert Protobuf.Validator.valid?(cluster)
  end

  test "cluster with options" do
    alias Envoy.Api.V2.Core.Http2ProtocolOptions
    alias Google.Protobuf.UInt32Value
    lb_policy = Cluster.LbPolicy.value(:MAGLEV)

    http2_protocol_options =
      Http2ProtocolOptions.new(max_concurrent_streams: UInt32Value.new(value: 100))

    app_endpoint = %AppEndpoint{
      @simple_app_endpoint
      | cluster_opts: [
          lb_policy: lb_policy,
          http2_protocol_options: http2_protocol_options
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
             lb_policy: ^lb_policy,
             http2_protocol_options: ^http2_protocol_options
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
