defmodule Envoy.Config.Metrics.V2.StatsSink do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          config: Google.Protobuf.Struct.t() | nil
        }
  defstruct [:name, :config]

  field :name, 1, type: :string
  field :config, 2, type: Google.Protobuf.Struct
end

defmodule Envoy.Config.Metrics.V2.StatsConfig do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          stats_tags: [Envoy.Config.Metrics.V2.TagSpecifier.t()],
          use_all_default_tags: Google.Protobuf.BoolValue.t() | nil
        }
  defstruct [:stats_tags, :use_all_default_tags]

  field :stats_tags, 1, repeated: true, type: Envoy.Config.Metrics.V2.TagSpecifier
  field :use_all_default_tags, 2, type: Google.Protobuf.BoolValue
end

defmodule Envoy.Config.Metrics.V2.TagSpecifier do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          tag_value: {atom, any},
          tag_name: String.t()
        }
  defstruct [:tag_value, :tag_name]

  oneof :tag_value, 0
  field :tag_name, 1, type: :string
  field :regex, 2, type: :string, oneof: 0
  field :fixed_value, 3, type: :string, oneof: 0
end

defmodule Envoy.Config.Metrics.V2.StatsdSink do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          statsd_specifier: {atom, any},
          prefix: String.t()
        }
  defstruct [:statsd_specifier, :prefix]

  oneof :statsd_specifier, 0
  field :address, 1, type: Envoy.Api.V2.Core.Address, oneof: 0
  field :tcp_cluster_name, 2, type: :string, oneof: 0
  field :prefix, 3, type: :string
end

defmodule Envoy.Config.Metrics.V2.DogStatsdSink do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          dog_statsd_specifier: {atom, any},
          prefix: String.t()
        }
  defstruct [:dog_statsd_specifier, :prefix]

  oneof :dog_statsd_specifier, 0
  field :address, 1, type: Envoy.Api.V2.Core.Address, oneof: 0
  field :prefix, 3, type: :string
end

defmodule Envoy.Config.Metrics.V2.HystrixSink do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          num_buckets: integer
        }
  defstruct [:num_buckets]

  field :num_buckets, 1, type: :int64
end
