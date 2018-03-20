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
    "relay.port": [
      commented: false,
      datatype: :integer,
      default: 5000,
      doc: "Port for discovery service to listen on",
      hidden: false,
      to: "relay.port"
    ],
    "relay.envoy.cluster_name": [
      commented: false,
      datatype: :binary,
      default: "xds_cluster",
      doc: "The cluster name for this discovery service in Envoy's bootstrap.yaml",
      hidden: false,
      to: "relay.envoy.cluster_name"
    ],
    "relay.envoy.max_obj_name_length": [
      commented: false,
      datatype: :integer,
      default: 60,
      doc: "The maximum length of Envoy object names",
      hidden: false,
      to: "relay.envoy.max_obj_name_length"
    ],
    "relay.marathon.urls": [
      commented: false,
      datatype: [
        list: :binary
      ],
      default: [
        "http://localhost:8080"
      ],
      doc: "URLs for Marathon's API endpoints",
      hidden: false,
      to: "relay.marathon.urls"
    ],
    "relay.marathon.events_timeout": [
      commented: false,
      datatype: :integer,
      default: 60000,
      doc: "Timeout value for Marathon's event stream",
      hidden: false,
      to: "relay.marathon.events_timeout"
    ],
    "relay.marathon_lb.group": [
      commented: false,
      datatype: :binary,
      default: "external",
      doc: "The marathon-lb group to expose via Envoy",
      hidden: false,
      to: "relay.marathon_lb.group"
    ],
    "relay.marathon_acme.app_id": [
      commented: false,
      datatype: :binary,
      default: "/marathon-acme",
      doc: "The Marathon app ID for marathon-acme",
      hidden: false,
      to: "relay.marathon_acme.app_id"
    ],
    "relay.marathon_acme.port_index": [
      commented: false,
      datatype: :integer,
      default: 0,
      doc: "The port index for marathon-acme",
      hidden: false,
      to: "relay.marathon_acme.port_index"
    ]
  ],
  transforms: [],
  validators: []
]
