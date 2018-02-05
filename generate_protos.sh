#!/usr/bin/env bash
# Based on the go-control-plane code:
# https://github.com/envoyproxy/go-control-plane/blob/cd217031c55a80342a864f9aff3b7a7f22205891/generate_protos.sh
# Requires:
# - protoc (`brew install protobuf`)
# - bazel (`brew install bazel`)
# - protoc-gen-elixir (`mix escript.install hex protobuf`)
set -o errexit
set -o nounset
set -o pipefail

root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Expecting protoc version >= 3.5.0:"
protoc=$(which protoc)
$protoc --version

echo "Expecting to find sibling data-plane-api repository ..."
pushd ../data-plane-api
	git log -1
	# FIXME: For some reason 'fetch' doesn't work so we do a complete build :-/
	bazel build //envoy/...
popd

elixirarg="plugins=grpc"

protocpaths=(
	../data-plane-api/
	../data-plane-api/bazel-data-plane-api/external/com_github_gogo_protobuf/
	../data-plane-api/bazel-data-plane-api/external/com_lyft_protoc_gen_validate/
	../data-plane-api/bazel-data-plane-api/external/googleapis/
)
protocarg=""
for path in "${protocpaths[@]}"; do
	protocarg="$protocarg -I=$path"
done

# TODO: Only generate the files we need.
echo "Generating protos $path..."
find ../data-plane-api/envoy/api -name '*.proto' | \
	xargs $protoc ${protocarg} --plugin=elixir --elixir_out="${elixirarg}":"${root}/lib/"
