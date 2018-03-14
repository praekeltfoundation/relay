defmodule Relay.EnvoyUtil do
  def api_config_source(options \\ []) do
    alias Envoy.Api.V2.Core.{ApiConfigSource, ConfigSource}

    cluster_name = Application.fetch_env!(:relay, :cluster_name)

    ConfigSource.new(
      config_source_specifier:
        {:api_config_source,
         ApiConfigSource.new(
           [
             api_type: ApiConfigSource.ApiType.value(:GRPC),
             cluster_names: [cluster_name]
           ] ++ options
         )}
    )
  end
end
