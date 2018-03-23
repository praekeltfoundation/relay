# Used by "mix format"

# The only way to adjust which files `mix format` considers is with the `input`
# option. It is possible to have different .formatter.exs files per-directory,
# but we'd rather not have config in many different files.

include_patterns = ["*.exs", "{config,gen,lib,test}/**/*.{ex,exs}"]

ignore_paths = [
  # TODO: Reduce this list
  "mix.exs",
  "config/config.exs",
  "lib/log_wrapper.ex",
  "lib/marathon_client.ex",
  "lib/marathon_client/sse_client.ex",
  "lib/marathon_client/sse_parser.ex",
  "lib/relay.ex",
  "lib/relay/certs.ex",
  "lib/relay/demo/certs.ex",
  "lib/relay/grpc_adapter.ex",
  "lib/relay/marathon/adapter.ex",
  "lib/relay/marathon/app.ex",
  "lib/relay/marathon/labels.ex",
  "lib/relay/marathon/networking.ex",
  "lib/relay/marathon/state.ex",
  "lib/relay/marathon/task.ex",
  "lib/relay/protobuf_util.ex",
  "lib/relay/publisher.ex",
  "lib/relay/server.ex",
  "lib/relay/supervisor.ex",
  "test/marathon_client/fake_marathon.exs",
  "test/marathon_client/marathon_client_helper.exs",
  "test/marathon_client/sse_client_test.exs",
  "test/marathon_client/sse_parser_test.exs",
  "test/relay/envoy_util_test.exs",
  "test/relay/marathon/adapter_test.exs",
  "test/relay/marathon/app_test.exs",
  "test/relay/marathon/labels_test.exs",
  "test/relay/marathon/networking_test.exs",
  "test/relay/marathon/state_test.exs",
  "test/relay/marathon/task_test.exs",
  "test/relay/protobuf_util_test.exs",
  "test/relay/publisher_test.exs",
  "test/relay/server_test.exs",
  "test/relay/supervisor_test.exs",
  "test/relay_test.exs",
  "test/test_helper.exs"
]

inputs =
  Enum.flat_map(include_patterns, fn pattern ->
    Path.wildcard(pattern, match_dot: true)
    |> Enum.filter(fn path -> not String.starts_with?(path, ignore_paths) end)
  end)

[
  # https://github.com/tony612/protobuf-elixir/blob/v0.5.3/lib/protobuf/protoc/generator.ex#L48
  locals_without_parens: [field: 2, field: 3, oneof: 2, rpc: 3],
  inputs: inputs
]
