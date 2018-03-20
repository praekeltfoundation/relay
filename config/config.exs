# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :relay, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:relay, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :relay, [
  listen: [
    address: {127, 0, 0, 1},
    port: 5000
  ],

  envoy: [
    cluster_name: "xds_cluster",
    max_obj_name_length: 60,
    listeners: [
      http: [
        http_connection_manager: [
          access_log: [
            path: "http_access.log",
            format: ""
            # TODO: Figure out how to configure filters
          ]
        ],
        router: [
          upstream_log: [
            path: "http_upstream.log",
            format: ""
            # TODO: Figure out how to configure filters
          ]
        ]
      ],
      https: [
        http_connection_manager: [
          access_log: [
            path: "https_access.log",
            format: ""
            # TODO: Figure out how to configure filters
          ]
        ],
        router: [
          upstream_log: [
            path: "https_upstream.log",
            format: ""
            # TODO: Figure out how to configure filters
          ]
        ]
      ]
    ]
  ],

  marathon: [
    urls: ["http://localhost:8080"],
    events_timeout: 60_000
  ],

  marathon_lb: [
    group: "external"
  ],

  marathon_acme: [
    app_id: "/marathon-acme",
    port_index: 0
  ]
]
