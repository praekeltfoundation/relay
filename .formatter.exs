# Used by "mix format"

# The only way to adjust which files `mix format` considers is with the `input`
# option. It is possible to have different .formatter.exs files per-directory,
# but we'd rather not have config in many different files.

include_patterns = ["*.exs", "{config,lib,test}/**/*.{ex,exs}"]

ignore_paths = [
  # TODO: Reduce this list
  "config/config.exs"
]

inputs =
  Enum.flat_map(include_patterns, fn pattern ->
    Path.wildcard(pattern, match_dot: true)
    |> Enum.filter(fn path -> not String.starts_with?(path, ignore_paths) end)
  end)

[
  import_deps: [:grpc, :protobuf],
  inputs: inputs,
  locals_without_parens: [xds_tests: 2]
]
