@moduledoc """
A schema is a keyword list which represents how to map, transform, and validate
configuration values parsed from the .conf file. The following is an explanation of
each key in the schema definition in order of appearance, and how to use them.

## Import

A list of application names (as atoms), which represent apps to load modules from
which you can then reference in your schema definition. This is how you import your
own custom Validator/Transform modules, or general utility modules for use in
validator/transform functions in the schema. For example, if you have an application
`:foo` which contains a custom Transform module, you would add it to your schema like so:

`[ import: [:foo], ..., transforms: ["myapp.some.setting": MyApp.SomeTransform]]`

## Extends

A list of application names (as atoms), which contain schemas that you want to extend
with this schema. By extending a schema, you effectively re-use definitions in the
extended schema. You may also override definitions from the extended schema by redefining them
in the extending schema. You use `:extends` like so:

`[ extends: [:foo], ... ]`

## Mappings

Mappings define how to interpret settings in the .conf when they are translated to
runtime configuration. They also define how the .conf will be generated, things like
documention, @see references, example values, etc.

See the moduledoc for `Conform.Schema.Mapping` for more details.

## Transforms

Transforms are custom functions which are executed to build the value which will be
stored at the path defined by the key. Transforms have access to the current config
state via the `Conform.Conf` module, and can use that to build complex configuration
from a combination of other config values.

See the moduledoc for `Conform.Schema.Transform` for more details and examples.

## Validators

Validators are simple functions which take two arguments, the value to be validated,
and arguments provided to the validator (used only by custom validators). A validator
checks the value, and returns `:ok` if it is valid, `{:warn, message}` if it is valid,
but should be brought to the users attention, or `{:error, message}` if it is invalid.

See the moduledoc for `Conform.Schema.Validator` for more details and examples.
"""
[
  extends: [],
  import: [],
  mappings: [
    "relay.listen.address": [
      commented: true,
      datatype: :binary,
      default: "127.0.0.1",
      doc: "Address to interface for discovery service to listen on",
      env_var: "RELAY_LISTEN_ADDRESS"
    ],
    "relay.listen.port": [
      commented: true,
      datatype: :integer,
      default: 5000,
      doc: "Port for discovery service to listen on",
      env_var: "RELAY_LISTEN_PORT"
    ],
    "relay.envoy.grpc.target_uri": [
      commented: true,
      datatype: :binary,
      default: "127.0.0.1:5000",
      doc: "The host:port address for Envoy to connect to this discovery service on",
      env_var: "RELAY_ENVOY_GRPC_TARGET_URI"
    ],
    "relay.envoy.grpc.stat_prefix": [
      commented: true,
      datatype: :binary,
      default: "xds_cluster",
      doc: "The prefix to use for Envoy's gRPC stats",
      env_var: "RELAY_ENVOY_GRPC_STAT_PREFIX"
    ],
    "relay.envoy.max_obj_name_length": [
      commented: true,
      datatype: :integer,
      default: 60,
      doc: "The maximum length of Envoy object names",
      env_var: "RELAY_ENVOY_MAX_OBJ_NAME_LENGTH"
    ],
    "relay.envoy.listeners.http.address": [
      commented: true,
      # These addresses aren't transformed because Envoy takes binary addresses
      datatype: :binary,
      default: "127.0.0.1",
      doc: "Address to interface for HTTP listener to listen on",
      env_var: "RELAY_ENVOY_LISTENERS_HTTP_ADDRESS",
      to: "relay.envoy.listeners.http.listen.address"
    ],
    "relay.envoy.listeners.http.port": [
      commented: true,
      datatype: :integer,
      doc: "Port for listener to listen on",
      default: 8080,
      env_var: "RELAY_ENVOY_LISTENERS_HTTP_PORT",
      to: "relay.envoy.listeners.http.listen.port"
    ],
    "relay.envoy.listeners.http.access_log.path": [
      commented: true,
      datatype: :binary,
      default: "http_access.log",
      doc: "Path to the access log file for incoming connections",
      env_var: "RELAY_ENVOY_LISTENERS_HTTP_ACCESS_LOG_PATH",
      to: "relay.envoy.listeners.http.http_connection_manager.access_log.path"
    ],
    "relay.envoy.listeners.http.access_log.format": [
      commented: true,
      datatype: :binary,
      default: "",
      doc: "Format for the access log for incoming connections",
      env_var: "RELAY_ENVOY_LISTENERS_HTTP_ACCESS_LOG_FORMAT",
      to: "relay.envoy.listeners.http.http_connection_manager.access_log.format"
    ],
    "relay.envoy.listeners.http.upstream_log.path": [
      commented: true,
      datatype: :binary,
      default: "http_upstream.log",
      doc: "Path to the upstream log file for incoming connections",
      env_var: "RELAY_ENVOY_LISTENERS_HTTP_UPSTREAM_LOG_PATH",
      to: "relay.envoy.listeners.http.http_connection_manager.upstream_log.path"
    ],
    "relay.envoy.listeners.http.upstream_log.format": [
      commented: true,
      datatype: :binary,
      default: "",
      doc: "Format for the upstream log for incoming connections",
      env_var: "RELAY_ENVOY_LISTENERS_HTTP_UPSTREAM_LOG_FORMAT",
      to: "relay.envoy.listeners.http.http_connection_manager.upstream_log.format"
    ],
    "relay.envoy.listeners.http.use_remote_address": [
      commented: true,
      datatype: :boolean,
      default: true,
      doc:
        "Whether to use the real remote address of the client connection when determining origin",
      env_var: "RELAY_ENVOY_LISTENERS_HTTP_USE_REMOTE_ADDRESS",
      to: "relay.envoy.listeners.http.http_connection_manager.use_remote_address"
    ],
    "relay.envoy.listeners.https.address": [
      commented: true,
      # These addresses aren't transformed because Envoy takes binary addresses
      datatype: :binary,
      default: "127.0.0.1",
      doc: "Address to interface for HTTPS listener to listen on",
      env_var: "RELAY_ENVOY_LISTENERS_HTTPS_ADDRESS",
      to: "relay.envoy.listeners.https.listen.address"
    ],
    "relay.envoy.listeners.https.port": [
      commented: true,
      datatype: :integer,
      doc: "Port for listener to listen on",
      default: 8443,
      env_var: "RELAY_ENVOY_LISTENERS_HTTPS_PORT",
      to: "relay.envoy.listeners.https.listen.port"
    ],
    "relay.envoy.listeners.https.access_log.path": [
      commented: true,
      datatype: :binary,
      default: "https_access.log",
      doc: "Path to the access log file for incoming connections",
      env_var: "RELAY_ENVOY_LISTENERS_HTTPS_ACCESS_LOG_PATH",
      to: "relay.envoy.listeners.https.http_connection_manager.access_log.path"
    ],
    "relay.envoy.listeners.https.access_log.format": [
      commented: true,
      datatype: :binary,
      default: "",
      doc: "Format for the access log for incoming connections",
      env_var: "RELAY_ENVOY_LISTENERS_HTTPS_ACCESS_LOG_FORMAT",
      to: "relay.envoy.listeners.https.http_connection_manager.access_log.format"
    ],
    "relay.envoy.listeners.https.upstream_log.path": [
      commented: true,
      datatype: :binary,
      default: "https_upstream.log",
      doc: "Path to the upstream log file for incoming connections",
      env_var: "RELAY_ENVOY_LISTENERS_HTTPS_UPSTREAM_LOG_PATH",
      to: "relay.envoy.listeners.https.http_connection_manager.upstream_log.path"
    ],
    "relay.envoy.listeners.https.upstream_log.format": [
      commented: true,
      datatype: :binary,
      default: "",
      doc: "Format for the upstream log for incoming connections",
      env_var: "RELAY_ENVOY_LISTENERS_HTTPS_UPSTREAM_LOG_FORMAT",
      to: "relay.envoy.listeners.https.http_connection_manager.upstream_log.format"
    ],
    "relay.envoy.listeners.https.use_remote_address": [
      commented: true,
      datatype: :boolean,
      default: true,
      doc:
        "Whether to use the real remote address of the client connection when determining origin",
      env_var: "RELAY_ENVOY_LISTENERS_HTTPS_USE_REMOTE_ADDRESS",
      to: "relay.envoy.listeners.https.http_connection_manager.use_remote_address"
    ],
    "relay.envoy.clusters.connect_timeout": [
      commented: true,
      datatype: :integer,
      default: 5_000,
      env_var: "RELAY_ENVOY_CLUSTERS_CONNECT_TIMEOUT",
      doc: "Default connect timeout for upstream clusters (ms)"
    ],
    "relay.envoy.clusters.endpoints.locality.region": [
      commented: true,
      datatype: :binary,
      default: "default",
      doc: "Default locality region for upstream endpoints"
    ],
    "relay.envoy.clusters.endpoints.locality.zone": [
      commented: true,
      datatype: :binary,
      default: "default",
      doc: "Default locality zone for upstream endpoints"
    ],
    "relay.envoy.clusters.endpoints.locality.sub_zone": [
      commented: true,
      datatype: :binary,
      default: "",
      doc: "Default locality sub-zone for upstream endpoints"
    ],
    "relay.marathon.urls": [
      commented: true,
      datatype: [list: :binary],
      default: ["http://localhost:8080"],
      doc: "URLs for Marathon's API endpoints",
      env_var: "RELAY_MARATHON_URLS"
    ],
    "relay.marathon.events_timeout": [
      commented: true,
      datatype: :integer,
      default: 60_000,
      doc: "Timeout value for Marathon's event stream (ms)",
      env_var: "RELAY_MARATHON_EVENTS_TIMEOUT"
    ],
    "relay.marathon_lb.group": [
      commented: true,
      datatype: :binary,
      default: "external",
      doc: "The marathon-lb group to expose via Envoy",
      env_var: "RELAY_MARATHON_LB_GROUP"
    ],
    "relay.marathon_acme.app_id": [
      commented: true,
      datatype: :binary,
      default: "/marathon-acme",
      doc: "The Marathon app ID for marathon-acme",
      env_var: "RELAY_MARATHON_ACME_APP_ID"
    ],
    "relay.marathon_acme.port_index": [
      commented: true,
      datatype: :integer,
      default: 0,
      doc: "The port index for marathon-acme",
      env_var: "RELAY_MARATHON_ACME_PORT_INDEX"
    ],
    # FIXME: Relay.Certs.Filesystem specific config should probably be in a subgroup.
    "relay.certs.paths": [
      commented: true,
      datatype: [list: :binary],
      default: [],
      doc: "Paths to read certificates from",
      env_var: "RELAY_CERTS_PATHS"
    ],
    # TODO: Relay.Certs.VaultKV config.
    "relay.certs.sync_period": [
      commented: true,
      datatype: :integer,
      default: 600_000,
      doc: "Time between scheduled full syncs (ms)",
      env_var: "RELAY_CERTS_SYNC_PERIOD"
    ],
    "relay.certs.mlb_port": [
      commented: true,
      datatype: :integer,
      default: 9090,
      doc: "Port to listen on for marathon-lb HTTP signals",
      env_var: "RELAY_CERTS_MLB_PORT"
    ],
    "relay.resolver.ttl": [
      commented: true,
      datatype: :integer,
      default: 60_000,
      doc: "Time-to-live for cached DNS responses",
      env_var: "RELAY_RESOLVER_TTL"
    ],
    # We need this configured for the GRPC server to work, but we don't really
    # want to make it user-configurable.
    "grpc.start_server": [
      datatype: :boolean,
      default: true,
      hidden: true
    ]
  ],
  transforms: [
    # In order to support multi-value environment variables for these fields,
    # we accept and split comma-separated strings. We have no way of knowing
    # whether the value we have came from a conf file, the environment, or the
    # default, so rather than trying to guess we just split all list items.
    "relay.marathon.urls": fn conf ->
      [{_, value}] = Conform.Conf.get(conf, "relay.marathon.urls")
      Enum.flat_map(value, &String.split(&1, ~r{,\s*}))
    end,
    "relay.certs.paths": fn conf ->
      [{_, value}] = Conform.Conf.get(conf, "relay.certs.paths")
      Enum.flat_map(value, &String.split(&1, ~r{,\s*}))
    end
  ],
  validators: []
]
