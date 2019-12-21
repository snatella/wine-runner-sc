#!/bin/bash

# For you to use (optionally) if you wish to package your completed build in a tgz

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

list=$(find $DIR/build -mindepth 1 -maxdepth 1 -type d | grep runner)

find $DIR/build -maxdepth 1 -name "*.tgz" -delete

for folder in $list; do
    echo "Building .tgz for $folder";

    if hash pigz 2>/dev/null; then
        tar -C $folder --use-compress-program="pigz --best --recursive" -cf $folder.tgz .
    else
        tar -C $folder -czf $folder.tgz .
    fi

    echo "$folder.tgz built"
done
