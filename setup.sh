#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

. $DIR/common.sh

if [[ "$http_proxy" != "" ]]; then
    echo "Proxy set, creating build_args to use it"
    export build_args="--build-arg http_proxy=$http_proxy --build-arg https_proxy=$http_proxy"
fi

if [[ "$do_amd64_build" != "no" ]]; then
    echo "Building 64bit Ubuntu Wine builder"
    docker build --pull --rm --tag wine-builder64:latest $build_args -f Dockerfile.64bit .
fi

if [[ "$do_i386_build" != "no" ]]; then
    echo "Building 32bit Ubuntu Wine builder"
    docker build --pull --rm --tag wine-builder32:latest $build_args -f Dockerfile.32bit .
fi

if [[ "$do_prune" == "yes" ]]; then
    echo "Clearing up any intermediates"
    docker image prune -f
fi

echo "Setup complete"
