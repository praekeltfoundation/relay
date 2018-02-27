#!/usr/bin/env bash
# Based on the go-control-plane code:
# https://github.com/envoyproxy/go-control-plane/blob/cd217031c55a80342a864f9aff3b7a7f22205891/generate_protos.sh
# Requires:
# - bazel (`brew install bazel`)
# - protoc (`brew install protobuf`)
# - protoc-gen-elixir (`mix escript.install hex protobuf`)
set -o errexit
set -o nounset
set -o pipefail

root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Expecting protoc version >= 3.5.0:"
protoc=$(which protoc)
$protoc --version
echo

echo "Fetching/updating submodules..."
git submodule init
git submodule sync
git submodule update --checkout
echo "Checking submodules..."
git submodule status
echo

echo "Fetching data-plane-api dependencies..."
pushd data-plane-api
bazel fetch //envoy/...
output_base="$(bazel info output_base)"
popd
echo

generated_paths=(
	lib/envoy
	lib/google
)
echo "Deleting existing generated code..."
for path in "${generated_paths[@]}"; do
	rm_cmd="rm -rf $root/$path" && echo "$rm_cmd" && $rm_cmd
done
echo

elixirarg="plugins=grpc"

deps=(
	com_github_gogo_protobuf
	com_lyft_protoc_gen_validate
	googleapis
)
protocargs=("-I=data-plane-api")
for dep in "${deps[@]}"; do
	protocargs+=("-I=$output_base/external/$dep")
done

data_plane_modules=(
	api
	config
	type
)

# TODO: Only generate the files we need.
echo "Generating data-plane-api protos..."
for module in "${data_plane_modules[@]}"; do
	find data-plane-api/envoy/"$module" -name '*.proto' | \
		xargs $protoc ${protocargs[@]} --plugin=elixir --elixir_out="${elixirarg}":"${root}/lib/"
done
echo

echo "The following Google protos are used:"
grep -REho '\bGoogle.[A-Z]\w+.[A-Z]\w*' lib/envoy | sort -u
echo

# These are the protos under 'Google.Protobuf'
protobuf_protos=(
	any
	duration
	struct
	# Google.Protobuf.Timestamp was added to elixir-protobuf (0.5.2+)
	# https://github.com/tony612/protobuf-elixir/pull/25
	# timestamp
	wrappers
)

echo "Generating protobuf protos..."
protobuf_src="$output_base/external/com_google_protobuf/src"
# These have no dependencies
for proto in "${protobuf_protos[@]}"; do
	$protoc -I="$protobuf_src" --plugin=elixir --elixir_out="${elixirarg}":"${root}/lib/" \
		"$protobuf_src"/google/protobuf/"$proto".proto
done
echo


# These are the protos *not* under 'Google.Protobuf'
googleapis_protos=(
	rpc/status
)

echo "Generating googleapis protos..."
googleapis_src="$output_base/external/googleapis"
# These *implicitly* depend on the Google.Protobuf APIs
for proto in "${googleapis_protos[@]}"; do
	$protoc -I="$googleapis_src" --plugin=elixir --elixir_out="${elixirarg}":"${root}/lib/" \
		"$googleapis_src"/google/"$proto".proto
done
