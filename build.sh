#!/bin/bash

# For you to build a bi-arch wine on ubuntu docker images. See README.md for more details.

set -e

if [[ "$wine_version" == "" ]]; then
    echo "Please set wine_version to continue, e.g. export wine_version=4.20"
    exit 1
fi

rm -rf build/
mkdir build

echo "docker build --pull --rm --tag lug-runner:$wine_version --build-arg wine_version=$wine_version $docker_args ."
docker build --pull --rm --tag lug-runner:$wine_version --build-arg wine_version=$wine_version $docker_args .

docker create -ti --name lug-loader-$wine_version lug-runner:$wine_version bash

docker cp lug-loader-$wine_version:/root/wine-build-64/ build/wine64
docker cp lug-loader-$wine_version:/root/wine-build-32/ build/wine32

docker rm -f lug-loader-$wine_version

cd build \
    && mkdir wine-runner-$wine_version \
    && cp -a wine64/* wine-runner-$wine_version/ \
    && cp -a -n wine32/* wine-runner-$wine_version/ \
    && rm -rf wine32 && rm -rf wine64

if [[ "$do_prune" == "yes" ]]; then
    docker image prune -f
    docker rmi lug-runner:$wine_version
fi

echo "build/wine-runner-$wine_version created"
