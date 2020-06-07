#!/bin/bash

set -e

if [[ "$1" == "" ]]; then
    echo "Please pass a wine version";
    exit 1;
fi

cd "${0%/*}"

export wine_version=$1;
export do_wine_staging=no
unset wine_staging_list

rm -f ./build/*.tgz

subname="";

if [[ "$do_amd64_build" == "no" ]]; then
    subname="-i386";
elif [[ "$do_i386_build" == "no" ]]; then
    subname="-amd64";
fi

echo "Running setup."

./setup.sh

echo "Building vanilla runner."

runner_name="wine-runner-${wine_version}$subname"

./wine-git.sh && \
    echo "Building... (See $PWD/build/${wine_version}.log for details)" && \
    /usr/bin/time -f "Elapsed: %E" ./build-wine.sh > ./build/${wine_version}.log 2>&1 && \
    tar -C "./build/wine-runner-$wine_version" -czf "./build/$runner_name.tgz" . && \
    echo "$PWD/build/$runner_name.tgz created"

export do_wine_staging=yes

echo "Building staging runner."

runner_name="wine-runner-${wine_version}-staging$subname"

./wine-git.sh && \
    echo "Building... (See $PWD/build/${wine_version}-staging.log for details)" && \
    /usr/bin/time -f "Elapsed: %E" ./build-wine.sh > ./build/${wine_version}-staging.log 2>&1 && \
    tar -C "./build/wine-runner-$wine_version" -czf "./build/$runner_name.tgz" . && \
    echo "$PWD/build/$runner_name.tgz created"
