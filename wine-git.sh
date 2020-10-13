#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

. $DIR/common.sh

if [[ "$wine_version" == "" ]]; then
    echo "Please set wine_version to continue, e.g. export wine_version=4.21"
    exit 1
fi

if [[ "$no_limit_depth" == "yes" ]]; then
    echo "Not limiting depth - beware, checkout will be slow."
    checkout_depth=""
elif [[ "$limit_depth" != "" ]]; then
    checkout_depth="--depth $limit_depth"
else
    checkout_depth="--depth 1"
fi

#if [[ "$http_proxy" != "" ]]; then
#    git config --global http.proxy $http_proxy
#fi

echo "Clearing previous"
rm -rf $DIR/build/wine-git/
rm -rf $DIR/build/wine-staging/
rm -rf $DIR/build/data64/{build,wine-cfg}
rm -rf $DIR/build/data32/{build,wine-cfg,wine-tools}

echo "Cloning wine from git"
if [[ "$wine_version" == "master" ]]; then
    git clone $checkout_depth --branch master ${wine_repo} $DIR/build/wine-git
else
    git clone $checkout_depth --branch wine-${wine_version} ${wine_repo} $DIR/build/wine-git
fi

if [[ "$do_wine_staging" == "yes" ]]; then
    echo "Doing wine staging"
    if [[ "$wine_staging_list" == "" ]]; then
        echo "with default patch list (did you mean to set one with wine_staging_list?)"
        wine_staging_list="wined3d* d3d11* winex11-Vulkan_support"
    fi

    echo "Cloning wine staging from git"
    if [[ "$wine_staging_version" != "" ]]; then
        git clone $checkout_depth --branch ${wine_staging_version} ${wine_staging_repo} $DIR/build/wine-staging
    else
        git clone $checkout_depth --branch v${wine_version} ${wine_staging_repo} $DIR/build/wine-staging
    fi

    cd $DIR/build/wine-staging

    staging_extra_exclude=""
    if [[ "$wine_staging_exclude" != "" ]]; then
        echo "Excluding $wine_staging_exclude"
        staging_extra_exclude="-W $wine_staging_exclude"
    fi

    if [[ "$wine_staging_list" == "all" ]] || [[ "$wine_staging_list" == "*" ]]; then
        echo "Installing ALL wine staging patches"
        set -x
        docker run --rm -t -v $DIR/build:/build --name wine-builder-patcher wine-builder64:latest /build/wine-staging/patches/patchinstall.sh DESTDIR=/build/wine-git/ --force-autoconf --all $staging_extra_exclude
    else
        patchlist=""

        echo "Expanding patch list expansions..."
        for match in $wine_staging_list; do
            patchlist="$patchlist $(cd patches && echo $match)"
        done

        echo "Run patcher (in container)"
        set -x
        docker run --rm -t -v $DIR/build:/build --name wine-builder-patcher wine-builder64:latest /build/wine-staging/patches/patchinstall.sh DESTDIR=/build/wine-git/ --force-autoconf $staging_extra_exclude $patchlist
    fi

    docker run --rm -t -v $DIR/build:/build --name wine-builder-patcher wine-builder64:latest chown -R $UID:$UID /build/
    set +x

    echo "Fixed permissions in $DIR/build"
fi

echo "Checking for/applying local patches"
cd $DIR/build/wine-git

do_patches() {
    local dir="$1"

    for file in $(ls $dir/*.patch 2> /dev/null || true); do
        echo "Applying $file"
        patch -l -p1 < $file
    done
}

if [[ -e "$DIR/patches/$wine_version/staging" ]] && [[ "$do_wine_staging" == "yes" ]]; then
    echo "Found staging patch folder"
    do_patches "$DIR/patches/$wine_version/staging"
elif [[ -e "$DIR/patches/$wine_version" ]]; then
    echo "Found patch folder"
    do_patches "$DIR/patches/$wine_version"
else
    echo "No patches found for $wine_version";
fi

echo "Wine $wine_version ready for build"

if [[ "$do_wine_staging" == "yes" ]]; then
    echo "... with staging '$wine_staging_list'"
    if [[ "$wine_staging_list" == "all" ]] || [[ "$wine_staging_list" == "*" ]]; then
        echo "... which is ALL patches"
    else
        echo "... which expanded to '$patchlist'"
    fi
else
    echo "... without staging"
fi
