#!/bin/bash

set -e

export PATH="/usr/lib/ccache:$PATH"

VERSION="$1"

if [[ "$VERSION" == "" ]]; then
    echo "Please pass a version number parameter"
    exit 1
fi

echo "Setting up ccache"
ccache -F 0 && ccache -M 0

ccache --set-config=cache_dir=/build/data64/ccache

echo "Building wine64"
cd /build/data64/wine-cfg

/build/wine-git/configure --enable-win64 --prefix=/build/data64/build

make -j${build_cores} install

cp -a /build/data64/build/* /build/wine-runner-$VERSION/

echo "64bit build complete"
