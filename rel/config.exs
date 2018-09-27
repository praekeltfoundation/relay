use Mix.Releases.Config,
    default_release: :relay,
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :dev_test_cookie
end

environment :prod do
  set include_erts: true
  set include_src: false
  # The pre_start hook sets $ERLANG_COOKIE to a random value if is unset.
  set pre_configure_hooks: "rel/hooks/pre_configure.d"
  set cookie: "${ERLANG_COOKIE}"
  set config_providers: [
    {Mix.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
  ]
  set overlays: [
    {:copy, "rel/config/config.exs", "etc/config.exs"}
  ]
end

release :relay do
  set version: current_version(:relay)
  set applications: [
    :runtime_tools
  ]
end
