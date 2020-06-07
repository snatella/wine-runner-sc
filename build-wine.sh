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

echo "Remove 0 byte ccache files"
find "$DIR/build/data32/ccache" -size 0 -delete
find "$DIR/build/data64/ccache" -size 0 -delete

if [[ "$no_trim_ccache" != "no" ]]; then
    echo "Trim ccache files older than 14 days"
    find "$DIR/build/data32/ccache" -type f -mtime +14 -delete
    find "$DIR/build/data64/ccache" -type f -mtime +14 -delete
fi

if [[ "$build_cores" == "" ]]; then
    cores=$(grep processor /proc/cpuinfo | wc -l)
    build_cores="$(($cores+1))"
    echo "Automatically setting build cores to $build_cores, you can override by setting build_cores (usually number of cores/threads + 1 or 2 is advised)."
fi

if [[ "$do_amd64_build" == "no" ]] && [[ "$do_i386_build" == "no" ]]; then
    echo "Not building 64 or 32 bit runner? Bailing (you have both do_amd64_build=no and do_i386_build=no"
    exit 1
fi

if [[ "$do_amd64_build" != "no" ]]; then
    echo "docker run --rm -t -v $DIR/build:/build --env build_cores=$build_cores --name wine-builder64 wine-builder64:latest ./build64.sh $wine_version"
    docker run --rm -t -v $DIR/build:/build --env build_cores=$build_cores --name wine-builder64 wine-builder64:latest ./build64.sh $wine_version

    echo "docker run --rm -t -v $DIR/build:/build --name wine-builder64 wine-builder64:latest chown -R $UID:$UID /build/"
    docker run --rm -t -v $DIR/build:/build --name wine-builder64 wine-builder64:latest chown -R $UID:$UID /build/
fi

if [[ "$do_i386_build" != "no" ]]; then
    echo "docker run --rm -t -v $DIR/build:/build --env build_cores=$build_cores --name wine-builder32 wine-builder32:latest ./build32.sh $wine_version"
    docker run --rm -t -v $DIR/build:/build --env build_cores=$build_cores --name wine-builder32 wine-builder32:latest ./build32.sh $wine_version

    echo "docker run --rm -t -v $DIR/build:/build --name wine-builder32 wine-builder32:latest chown -R $UID:$UID /build/"
    docker run --rm -t -v $DIR/build:/build --name wine-builder32 wine-builder32:latest chown -R $UID:$UID /build/
else
    echo "docker run --rm -t -v $DIR/build:/build --name wine-builder64 wine-builder64:latest ln -s -f wine64 /build/wine-runner-$wine_version/bin/wine"
    docker run --rm -t -v $DIR/build:/build --name wine-builder64 wine-builder64:latest ln -s -f wine64 /build/wine-runner-$wine_version/bin/wine

    echo "docker run --rm -t -v $DIR/build:/build --name wine-builder64 wine-builder64:latest chown $UID:$UID /build/wine-runner-$wine_version/bin/wine"
    docker run --rm -t -v $DIR/build:/build --name wine-builder64 wine-builder64:latest chown $UID:$UID /build/wine-runner-$wine_version/bin/wine
fi

echo "Build complete in $DIR/build/wine-runner-$wine_version"
