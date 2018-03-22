# Used by "mix format"

include_patterns = ["*.exs", "{config,lib,test}/**/*.{ex,exs}"]

ignore_paths = [
  "lib/envoy/",
  "lib/google/",
  # TODO: Reduce this list
  ".formatter.exs",
  "mix.exs",
  "config/config.exs",
  "config/relay.schema.exs",
  "lib/log_wrapper.ex",
  "lib/marathon_client.ex",
  "lib/marathon_client/sse_client.ex",
  "lib/marathon_client/sse_parser.ex",
  "lib/relay.ex",
  "lib/relay/certs.ex",
  "lib/relay/demo/certs.ex",
  "lib/relay/demo/marathon.ex",
  "lib/relay/envoy_util.ex",
  "lib/relay/grpc_adapter.ex",
  "lib/relay/marathon/adapter.ex",
  "lib/relay/marathon/app.ex",
  "lib/relay/marathon/labels.ex",
  "lib/relay/marathon/networking.ex",
  "lib/relay/marathon/state.ex",
  "lib/relay/marathon/task.ex",
  "lib/relay/protobuf_util.ex",
  "lib/relay/publisher.ex",
  "lib/relay/resources.ex",
  "lib/relay/resources/lds.ex",
  "lib/relay/server.ex",
  "lib/relay/supervisor.ex",
  "test/marathon_client/fake_marathon.exs",
  "test/marathon_client/marathon_client_helper.exs",
  "test/marathon_client/sse_client_test.exs",
  "test/marathon_client/sse_parser_test.exs",
  "test/marathon_client_test.exs",
  "test/relay/certs_test.exs",
  "test/relay/envoy_util_test.exs",
  "test/relay/marathon/adapter_test.exs",
  "test/relay/marathon/app_test.exs",
  "test/relay/marathon/labels_test.exs",
  "test/relay/marathon/networking_test.exs",
  "test/relay/marathon/state_test.exs",
  "test/relay/marathon/task_test.exs",
  "test/relay/protobuf_util_test.exs",
  "test/relay/publisher_test.exs",
  "test/relay/resources_test.exs",
  "test/relay/server_test.exs",
  "test/relay/supervisor_test.exs",
  "test/relay_test.exs",
  "test/test_helper.exs"
]

[
  # Unfortunately, mix format doesn't have a way to ignore paths...
  inputs:
    Enum.flat_map(include_patterns, fn pattern ->
      Path.wildcard(pattern, match_dot: true)
      |> Enum.filter(fn path -> not String.starts_with?(path, ignore_paths) end)
    end)
]
