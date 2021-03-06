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
pushd envoy
patch -p1 < ../bazel-fetch-fix.patch
bazel fetch @envoy_api//envoy/...
patch -p1 -R < ../bazel-fetch-fix.patch

output_base="$(bazel info output_base)"
popd
echo

generated_paths=(
	gen/envoy
	gen/google
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
protocargs=("-I=envoy/api")
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
	find envoy/api/envoy/"$module" -name '*.proto' | \
		xargs $protoc ${protocargs[@]} --plugin=elixir --elixir_out="${elixirarg}":"${root}/gen/"
done
echo

google_protos="$(grep -REho '\bGoogle\.[A-Z]\w+\.[A-Z]\w*' gen/envoy | sort -u)"
echo "The following Google.Protobuf protos are used:"
echo "$google_protos" | grep -E '^Google\.Protobuf\.'
echo
echo "The following Google.* protos are used:"
echo "$google_protos" | grep -vE '^Google\.Protobuf\.'
echo

# These are the protos *not* under 'Google.Protobuf'
googleapis_protos=(
	rpc/status
)

echo "Generating googleapis protos..."
googleapis_src="$output_base/external/googleapis"
# These *implicitly* depend on the Google.Protobuf APIs
for proto in "${googleapis_protos[@]}"; do
	$protoc -I="$googleapis_src" --plugin=elixir --elixir_out="${elixirarg}":"${root}/gen/" \
		"$googleapis_src"/google/"$proto".proto
done
