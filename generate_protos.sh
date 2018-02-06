#!/usr/bin/env bash
# Based on the go-control-plane code:
# https://github.com/envoyproxy/go-control-plane/blob/cd217031c55a80342a864f9aff3b7a7f22205891/generate_protos.sh
# Requires:
# - protoc (`brew install protobuf`)
# - protoc-gen-elixir (`mix escript.install hex protobuf`)
set -o errexit
set -o nounset
set -o pipefail

root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Expecting protoc version >= 3.5.0:"
protoc=$(which protoc)
$protoc --version

pushd protobufs
	echo "Expecting to find data-plane-api submodule..."
	pushd data-plane-api
		git log -1
	popd

	pushd deps
		echo "Expecting to find com_github_gogo_protobuf submodule..."
		pushd com_github_gogo_protobuf
			git log -1
		popd

		echo "Expecting to find com_lyft_protoc_gen_validate submodule..."
		pushd com_lyft_protoc_gen_validate
			git log -1
		popd

		echo "Expecting to find googleapis submodule..."
		pushd googleapis
			git log -1
		popd
	popd

	echo "Expecting to find googleapis submodule..."
	pushd protobuf
		git log -1
	popd
popd

elixirarg="plugins=grpc"

deps=(
	com_github_gogo_protobuf
	com_lyft_protoc_gen_validate
	googleapis
)
protocargs=("-I=protobufs/data-plane-api")
for dep in "${deps[@]}"; do
	protocargs+=("-I=protobufs/deps/$dep")
done

# TODO: Only generate the files we need.
echo "Generating data-plane-api protos..."
find protobufs/data-plane-api/envoy/api -name '*.proto' | \
	xargs $protoc ${protocargs[@]} --plugin=elixir --elixir_out="${elixirarg}":"${root}/lib/"


# :-/
# rg --no-filename -o '\bGoogle.Protobuf.[A-Z]\w*' lib/envoy/ | sort -u
protobuf_protos=(
	any
	duration
	struct
	wrappers
)

echo "Generating protobuf protos..."
# These have no dependencies
for proto in "${protobuf_protos[@]}"; do
	$protoc -I=protobufs/protobuf/src --plugin=elixir --elixir_out="${elixirarg}":"${root}/lib/" \
		protobufs/protobuf/src/google/protobuf/"$proto".proto
done
