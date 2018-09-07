# This is a runtime configuration script. Compile-time config data (from the
# standard mix config.exs) is already available in the application environment
# at this point. See that for default values.
use Mix.Config

defmodule Cfg do

  def get_env_value(app, dotted_key, env_var, type) do
    keys =
      dotted_key
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)
    case env_var |> System.get_env() |> typed_value(type) do
      nil -> []
      val ->
        app_env = Application.get_all_env(app)
        new_env = Mix.Config.merge([{app, app_env}], [{app, build_config(keys, val)}])
        Mix.Config.persist(new_env)
    end
  end

  def build_config([], value), do: value
  def build_config([key | keys], value), do: [{key, build_config(keys, value)}]

  # TODO: Better errors, etc.
  def typed_value(nil, _), do: nil
  def typed_value(val, :binary), do: val
  def typed_value(val, :atom), do: String.to_atom(val)
  def typed_value(val, :integer) do
    {int, ""} = Integer.parse(val)
    int
  end
  def typed_value(val, [enum: vals]) do
    atom = typed_value(val, :atom)
    true = atom in vals
    atom
  end
  def typed_value(val, [list: type]) do
    val
    |> String.split(~r{,\s*})
    |> Enum.map(&typed_value(&1, type))
  end
end

# The following config is generated from the previous Conform schema by
# removing the @moduledoc header and running the following in iex:
#
# mkblock = fn {k, v} -> "# #{Keyword.get(v, :doc)}
#    Cfg.get_env_value(\"#{k}\", #{inspect(Keyword.get(v, :env_var))}, #{inspect(Keyword.get(v, :datatype))})\n" end
#
# {stuff, _} = Mix.Config.eval!("config/relay.schema.exs")
# stuff |> Keyword.get(:mappings) |> Enum.each(fn b -> IO.puts(mkblock.(b)) end)


# Global log level
Cfg.get_env_value(:logger, "level", "LOGGER_LEVEL", [enum: [:debug, :info, :warn, :error]])

# Address to interface for discovery service to listen on
Cfg.get_env_value(:relay, "listen.address", "RELAY_LISTEN_ADDRESS", :binary)

# Port for discovery service to listen on
Cfg.get_env_value(:relay, "listen.port", "RELAY_LISTEN_PORT", :integer)

# The host:port address for Envoy to connect to this discovery service on
Cfg.get_env_value(:relay, "envoy.grpc.target_uri", "RELAY_ENVOY_GRPC_TARGET_URI", :binary)

# The prefix to use for Envoy's gRPC stats
Cfg.get_env_value(:relay, "envoy.grpc.stat_prefix", "RELAY_ENVOY_GRPC_STAT_PREFIX", :binary)

# The maximum length of Envoy object names
Cfg.get_env_value(:relay, "envoy.max_obj_name_length", "RELAY_ENVOY_MAX_OBJ_NAME_LENGTH", :integer)

# Address to interface for HTTP listener to listen on
Cfg.get_env_value(:relay, "envoy.listeners.http.address", "RELAY_ENVOY_LISTENERS_HTTP_ADDRESS", :binary)

# Port for listener to listen on
Cfg.get_env_value(:relay, "envoy.listeners.http.port", "RELAY_ENVOY_LISTENERS_HTTP_PORT", :integer)

# Path to the access log file for incoming connections
Cfg.get_env_value(:relay, "envoy.listeners.http.access_log.path", "RELAY_ENVOY_LISTENERS_HTTP_ACCESS_LOG_PATH", :binary)

# Format for the access log for incoming connections
Cfg.get_env_value(:relay, "envoy.listeners.http.access_log.format", "RELAY_ENVOY_LISTENERS_HTTP_ACCESS_LOG_FORMAT", :binary)

# Path to the upstream log file for incoming connections
Cfg.get_env_value(:relay, "envoy.listeners.http.upstream_log.path", "RELAY_ENVOY_LISTENERS_HTTP_UPSTREAM_LOG_PATH", :binary)

# Format for the upstream log for incoming connections
Cfg.get_env_value(:relay, "envoy.listeners.http.upstream_log.format", "RELAY_ENVOY_LISTENERS_HTTP_UPSTREAM_LOG_FORMAT", :binary)

# Whether to use the real remote address of the client connection when determining origin
Cfg.get_env_value(:relay, "envoy.listeners.http.use_remote_address", "RELAY_ENVOY_LISTENERS_HTTP_USE_REMOTE_ADDRESS", :boolean)

# Address to interface for HTTPS listener to listen on
Cfg.get_env_value(:relay, "envoy.listeners.https.address", "RELAY_ENVOY_LISTENERS_HTTPS_ADDRESS", :binary)

# Port for listener to listen on
Cfg.get_env_value(:relay, "envoy.listeners.https.port", "RELAY_ENVOY_LISTENERS_HTTPS_PORT", :integer)

# Path to the access log file for incoming connections
Cfg.get_env_value(:relay, "envoy.listeners.https.access_log.path", "RELAY_ENVOY_LISTENERS_HTTPS_ACCESS_LOG_PATH", :binary)

# Format for the access log for incoming connections
Cfg.get_env_value(:relay, "envoy.listeners.https.access_log.format", "RELAY_ENVOY_LISTENERS_HTTPS_ACCESS_LOG_FORMAT", :binary)

# Path to the upstream log file for incoming connections
Cfg.get_env_value(:relay, "envoy.listeners.https.upstream_log.path", "RELAY_ENVOY_LISTENERS_HTTPS_UPSTREAM_LOG_PATH", :binary)

# Format for the upstream log for incoming connections
Cfg.get_env_value(:relay, "envoy.listeners.https.upstream_log.format", "RELAY_ENVOY_LISTENERS_HTTPS_UPSTREAM_LOG_FORMAT", :binary)

# Whether to use the real remote address of the client connection when determining origin
Cfg.get_env_value(:relay, "envoy.listeners.https.use_remote_address", "RELAY_ENVOY_LISTENERS_HTTPS_USE_REMOTE_ADDRESS", :boolean)

# Default connect timeout for upstream clusters (ms)
Cfg.get_env_value(:relay, "envoy.clusters.connect_timeout", "RELAY_ENVOY_CLUSTERS_CONNECT_TIMEOUT", :integer)

# # Default locality region for upstream endpoints
# Cfg.get_env_value(:relay, "envoy.clusters.endpoints.locality.region", nil, :binary)

# # Default locality zone for upstream endpoints
# Cfg.get_env_value(:relay, "envoy.clusters.endpoints.locality.zone", nil, :binary)

# # Default locality sub-zone for upstream endpoints
# Cfg.get_env_value(:relay, "envoy.clusters.endpoints.locality.sub_zone", nil, :binary)

# URLs for Marathon's API endpoints
Cfg.get_env_value(:relay, "marathon.urls", "RELAY_MARATHON_URLS", [list: :binary])

# Timeout value for Marathon's event stream (ms)
Cfg.get_env_value(:relay, "marathon.events_timeout", "RELAY_MARATHON_EVENTS_TIMEOUT", :integer)

# The marathon-lb group to expose via Envoy
Cfg.get_env_value(:relay, "marathon_lb.group", "RELAY_MARATHON_LB_GROUP", :binary)

# The Marathon app ID for marathon-acme
Cfg.get_env_value(:relay, "marathon_acme.app_id", "RELAY_MARATHON_ACME_APP_ID", :binary)

# The port index for marathon-acme
Cfg.get_env_value(:relay, "marathon_acme.port_index", "RELAY_MARATHON_ACME_PORT_INDEX", :integer)

# Paths to read certificates from
Cfg.get_env_value(:relay, "certs.paths", "RELAY_CERTS_PATHS", [list: :binary])

# Time between scheduled full syncs (ms)
Cfg.get_env_value(:relay, "certs.sync_period", "RELAY_CERTS_SYNC_PERIOD", :integer)

# Port to listen on for marathon-lb HTTP signals
Cfg.get_env_value(:relay, "certs.mlb_port", "RELAY_CERTS_MLB_PORT", :integer)

# Time-to-live for cached DNS responses
Cfg.get_env_value(:relay, "resolver.ttl", "RELAY_RESOLVER_TTL", :integer)
