# Used by "mix format"

# The default glob pattern matching doesn't match files starting with a '.'
inputs = ["*.exs", "{config,lib,test}/**/*.{ex,exs}"] ++ Path.wildcard(".*.exs", match_dot: true)

[
  import_deps: [:grpc, :protobuf],
  inputs: inputs,
  locals_without_parens: [xds_tests: 2]
]
