defmodule Relay.Resources.EDSTest do
  use ExUnit.Case, async: true

  alias Relay.Resolver
  alias Relay.Resources.{AppEndpoint, EDS}

  alias Envoy.Api.V2.ClusterLoadAssignment
  alias Envoy.Api.V2.Core.{Address, SocketAddress}
  alias Envoy.Api.V2.Endpoint.{Endpoint, LbEndpoint, LocalityLbEndpoints}

  @simple_app_endpoint %AppEndpoint{
    name: "/mc2_0",
    addresses: [{"10.70.4.100", 15979}]
  }

  setup do
    TestHelpers.override_log_level(:info)
    {:ok, _resolver} = start_supervised(Resolver)
    :ok
  end

  test "simple cluster load assignment" do
    assert [cla] = EDS.cluster_load_assignments([@simple_app_endpoint])

    locality = EDS.default_locality()

    assert %ClusterLoadAssignment{
             cluster_name: "/mc2_0",
             endpoints: [
               %LocalityLbEndpoints{
                 locality: ^locality,
                 lb_endpoints: [
                   %LbEndpoint{
                     endpoint: %Endpoint{
                       address: %Address{
                         address:
                           {:socket_address,
                            %SocketAddress{
                              address: "10.70.4.100",
                              port_specifier: {:port_value, 15979}
                            }}
                       }
                     }
                   }
                 ]
               }
             ]
           } = cla

    assert Protobuf.Validator.valid?(cla)
  end

  test "simple cluster load assignment no addresses" do
    app_endpoint = %AppEndpoint{@simple_app_endpoint | addresses: []}
    assert [cla] = EDS.cluster_load_assignments([app_endpoint])

    locality = EDS.default_locality()

    assert %ClusterLoadAssignment{
             cluster_name: "/mc2_0",
             endpoints: [
               %LocalityLbEndpoints{
                 locality: ^locality,
                 lb_endpoints: []
               }
             ]
           } = cla

    assert Protobuf.Validator.valid?(cla)
  end

  test "simple cluster load assignment two addresses" do
    app_endpoint = %AppEndpoint{
      @simple_app_endpoint
      | addresses: [{"10.70.4.100", 15979}, {"10.70.4.101", 15980}]
    }

    assert [cla] = EDS.cluster_load_assignments([app_endpoint])

    locality = EDS.default_locality()

    assert %ClusterLoadAssignment{
             cluster_name: "/mc2_0",
             endpoints: [
               %LocalityLbEndpoints{
                 locality: ^locality,
                 lb_endpoints: [
                   %LbEndpoint{
                     endpoint: %Endpoint{
                       address: %Address{
                         address:
                           {:socket_address,
                            %SocketAddress{
                              address: "10.70.4.100",
                              port_specifier: {:port_value, 15979}
                            }}
                       }
                     }
                   },
                   %LbEndpoint{
                     endpoint: %Endpoint{
                       address: %Address{
                         address:
                           {:socket_address,
                            %SocketAddress{
                              address: "10.70.4.101",
                              port_specifier: {:port_value, 15980}
                            }}
                       }
                     }
                   }
                 ]
               }
             ]
           } = cla

    assert Protobuf.Validator.valid?(cla)
  end

  test "simple cluster load assignment with hostname" do
    app_endpoint = Map.put(@simple_app_endpoint, :addresses, [{"localhost", 15979}])

    assert [cla] = EDS.cluster_load_assignments([app_endpoint])

    locality = EDS.default_locality()

    assert %ClusterLoadAssignment{
             cluster_name: "/mc2_0",
             endpoints: [
               %LocalityLbEndpoints{
                 locality: ^locality,
                 lb_endpoints: [
                   %LbEndpoint{
                     endpoint: %Endpoint{
                       address: %Address{
                         address:
                           {:socket_address,
                            %SocketAddress{
                              address: "127.0.0.1",
                              port_specifier: {:port_value, 15979}
                            }}
                       }
                     }
                   }
                 ]
               }
             ]
           } = cla

    assert Protobuf.Validator.valid?(cla)
  end

  test "override default locality" do
    alias Envoy.Api.V2.Core.Locality
    locality = Locality.new(region: "eu-west-1", zone: "eu-west-1b")

    app_endpoint = %AppEndpoint{@simple_app_endpoint | llb_endpoint_opts: [locality: locality]}

    assert [cla] = EDS.cluster_load_assignments([app_endpoint])

    assert %ClusterLoadAssignment{endpoints: [%LocalityLbEndpoints{locality: ^locality}]} = cla

    assert Protobuf.Validator.valid?(cla)
  end

  test "cluster load assignment with options" do
    alias Google.Protobuf.{UInt32Value, UInt64Value}

    app_endpoint = %AppEndpoint{
      @simple_app_endpoint
      | cla_opts: [policy: ClusterLoadAssignment.Policy.new(drop_overload: 5.0)],
        llb_endpoint_opts: [load_balancing_weight: UInt64Value.new(value: 42)],
        lb_endpoint_opts: [load_balancing_weight: UInt32Value.new(value: 13)]
    }

    assert [cla] = EDS.cluster_load_assignments([app_endpoint])

    assert %ClusterLoadAssignment{
             policy: %ClusterLoadAssignment.Policy{drop_overload: 5.0},
             endpoints: [
               %LocalityLbEndpoints{
                 load_balancing_weight: %UInt64Value{value: 42},
                 lb_endpoints: [
                   %LbEndpoint{load_balancing_weight: %UInt32Value{value: 13}}
                 ]
               }
             ]
           } = cla

    assert Protobuf.Validator.valid?(cla)
  end
end
