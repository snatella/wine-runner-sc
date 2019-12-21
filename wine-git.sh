#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

. $DIR/common.sh

if [[ "$wine_version" == "" ]]; then
    echo "Please set wine_version to continue, e.g. export wine_version=4.21"
    exit 1
fi

if [[ "$http_proxy" != "" ]]; then
    git config --global http.proxy $http_proxy
fi

echo "Clearing previous"
rm -rf $DIR/build/wine-git/
rm -rf $DIR/build/wine-staging/
rm -rf $DIR/build/data64/{build,wine-cfg}
rm -rf $DIR/build/data32/{build,wine-cfg,wine-tools}

echo "Cloning wine from git"
git clone --depth 1 --branch wine-${wine_version} ${wine_repo} $DIR/build/wine-git

if [[ "$do_wine_staging" == "yes" ]]; then
    echo "Doing wine staging"
    if [[ "$wine_staging_list" == "" ]]; then
        echo "with default patch list (did you mean to set one with wine_staging_list?)"
        wine_staging_list='wined3d* d3d11* d3dx9* dinput* ntdll-Dealloc_Thread_Stack ntdll-RtlCreateUserThread ntdll-Threading ntdll-ThreadTime server-Signal_Thread winex11-ime-check-thread-data'
    fi

    git clone --depth 1 --branch v${wine_version} ${wine_staging_repo} $DIR/build/wine-staging

    cd $DIR/build/wine-staging

    patchlist=""

    echo "Expanding patch list expansions..."
    for match in $wine_staging_list; do
        patchlist="$patchlist $(cd patches && echo $match)"
    done

    echo "Run patcher (in container)"
    set -x
    docker run --rm -t -v $DIR/build:/build --name wine-builder-patcher wine-builder64:latest /build/wine-staging/patches/patchinstall.sh DESTDIR=/build/wine-git/ --force-autoconf $patchlist

    docker run --rm -t -v $DIR/build:/build --name wine-builder-patcher wine-builder64:latest /usr/bin/chown -R $UID:$UID /build/
    set +x

    echo "Fixed permissions in $DIR/build"
fi

echo "Checking for/applying local patches"
cd $DIR/build/wine-git

for file in $(ls $DIR/patches/*.patch 2> /dev/null || true); do
    echo "Applying $file"
    patch -l -p1 < $file
done

echo "Wine git ready for build"
