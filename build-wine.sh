#!/bin/bash

# For you to build a bi-arch wine on ubuntu docker images. See README.md for more details.

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ "$wine_version" == "" ]]; then
    echo "Please set wine_version to continue, e.g. export wine_version=4.21"
    exit 1
fi

rm -rf "$DIR/build/wine-runner-${wine_version}/"

. $DIR/common.sh

mkdir "$DIR/build/wine-runner-${wine_version}/"

find "$DIR/build/data32/ccache" -size 0 -delete
find "$DIR/build/data64/ccache" -size 0 -delete

if [[ "$build_cores" == "" ]]; then
    cores=$(grep processor /proc/cpuinfo | wc -l)
    build_cores="$(($cores+1))"
    echo "Automatically setting build cores to $build_cores, you can override by setting build_cores (usually number of cores/threads + 1 or 2 is advised)."
fi

set -x

docker run --rm -t -v $DIR/build:/build --env build_cores=$build_cores --name wine-builder64 wine-builder64:latest ./build64.sh $wine_version

docker run --rm -t -v $DIR/build:/build --name wine-builder64 wine-builder64:latest chown -R $UID:$UID /build/

docker run --rm -t -v $DIR/build:/build --env build_cores=$build_cores --name wine-builder32 wine-builder32:latest ./build32.sh $wine_version

docker run --rm -t -v $DIR/build:/build --name wine-builder32 wine-builder32:latest chown -R $UID:$UID /build/

echo "Build complete in $DIR/build/wine-runner-$wine_version"
