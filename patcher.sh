#!/bin/bash

# Used by the dockerfile to apply patches and some wine-staging bits

set -e

staging_list='wined3d* d3d11* d3dx9* dinput* ntdll-Dealloc_Thread_Stack ntdll-RtlCreateUserThread ntdll-Threading ntdll-ThreadTime server-Signal_Thread winex11-ime-check-thread-data'
# For specifying which wine staging patches to apply. Wildcards are expanded.

do_wine_staging=$1
wine_staging_version=$2

if [[ "$do_wine_staging" == "yes" ]]; then
    git clone https://github.com/wine-staging/wine-staging.git ~/wine-staging

    cd ~/wine-staging

    if [[ "$wine_staging_version" != "" ]]; then
        git checkout $wine_staging_version
    fi

    patchlist=""

    for match in $staging_list; do
        patchlist="$patchlist $(cd patches && echo $match)"
    done

    echo "./patches/patchinstall.sh DESTDIR=~/wine-git --force-autoconf $patchlist"
    ./patches/patchinstall.sh DESTDIR=~/wine-git --force-autoconf $patchlist
fi

cd $HOME/wine-git

for file in $(ls ../patches/*.patch 2> /dev/null || true); do
    echo "Applying $file"
    patch -l -p1 <../patches/$file
done

echo "Done patching"
