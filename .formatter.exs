# Used by "mix format"

# The only way to adjust which files `mix format` considers is with the `input`
# option. It is possible to have different .formatter.exs files per-directory,
# but we'd rather not have config in many different files.

include_patterns = ["*.exs", "{config,lib,test}/**/*.{ex,exs}"]

[
  import_deps: [:grpc, :protobuf],
  # The default glob pattern matching doesn't match files starting with a '.'
  inputs: include_patterns |> Enum.flat_map(&Path.wildcard(&1, match_dot: true)),
  locals_without_parens: [xds_tests: 2]
]
