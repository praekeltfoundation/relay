use Mix.Releases.Config,
    default_release: :relay,
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"0*9Y&;PFP*aaA6&*m{tc;iU$kETxcc5lekB`iXp=a%O79M:3%dsFV0Y4>)?[VNr]"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"%I$29GGsz:z(FPCl(Al?O5Q_a}/p]k($GcJn8f%cORI6_I:_t.PkAUUQ[Jq7(@oV"
end

release :relay do
  set version: current_version(:relay)
  set applications: [
    :runtime_tools
  ]
  plugin Conform.ReleasePlugin
end
