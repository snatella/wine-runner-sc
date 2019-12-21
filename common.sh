#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mkdir -p build/{data64,data32,wine-git,wine-staging}
mkdir -p build/{data64,data32}/{wine-cfg,build,ccache}
mkdir -p build/data32/wine-tools

export wine_repo="https://github.com/wine-mirror/wine.git"
export wine_staging_repo="https://github.com/wine-staging/wine-staging.git"
