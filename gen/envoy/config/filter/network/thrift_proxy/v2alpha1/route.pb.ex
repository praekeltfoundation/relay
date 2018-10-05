defmodule Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.RouteConfiguration do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          routes: [Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.Route.t()]
        }
  defstruct [:name, :routes]

  field :name, 1, type: :string
  field :routes, 2, repeated: true, type: Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.Route
end

defmodule Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.Route do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          match: Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.RouteMatch.t(),
          route: Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.RouteAction.t()
        }
  defstruct [:match, :route]

  field :match, 1, type: Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.RouteMatch
  field :route, 2, type: Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.RouteAction
end

defmodule Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.RouteMatch do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          match_specifier: {atom, any},
          invert: boolean,
          headers: [Envoy.Api.V2.Route.HeaderMatcher.t()]
        }
  defstruct [:match_specifier, :invert, :headers]

  oneof :match_specifier, 0
  field :method_name, 1, type: :string, oneof: 0
  field :service_name, 2, type: :string, oneof: 0
  field :invert, 3, type: :bool
  field :headers, 4, repeated: true, type: Envoy.Api.V2.Route.HeaderMatcher
end

defmodule Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.RouteAction do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          cluster_specifier: {atom, any},
          metadata_match: Envoy.Api.V2.Core.Metadata.t()
        }
  defstruct [:cluster_specifier, :metadata_match]

  oneof :cluster_specifier, 0
  field :cluster, 1, type: :string, oneof: 0

  field :weighted_clusters, 2,
    type: Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.WeightedCluster,
    oneof: 0

  field :metadata_match, 3, type: Envoy.Api.V2.Core.Metadata
end

defmodule Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.WeightedCluster do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          clusters: [
            Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.WeightedCluster.ClusterWeight.t()
          ]
        }
  defstruct [:clusters]

  field :clusters, 1,
    repeated: true,
    type: Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.WeightedCluster.ClusterWeight
end

defmodule Envoy.Config.Filter.Network.ThriftProxy.V2alpha1.WeightedCluster.ClusterWeight do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          weight: Google.Protobuf.UInt32Value.t(),
          metadata_match: Envoy.Api.V2.Core.Metadata.t()
        }
  defstruct [:name, :weight, :metadata_match]

  field :name, 1, type: :string
  field :weight, 2, type: Google.Protobuf.UInt32Value
  field :metadata_match, 3, type: Envoy.Api.V2.Core.Metadata
end
