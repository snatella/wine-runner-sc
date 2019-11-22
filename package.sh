#!/bin/bash
set -e

list=$(find build -mindepth 1 -maxdepth 1 -type d)

find build -maxdepth 1 -name "*.tgz" -delete

for folder in $list; do
    echo $folder;

    if hash pigz2 2>/dev/null; then
        tar -C $folder --use-compress-program="pigz --best --recursive" -cf $folder.tgz .
    else
        tar -C $folder -cvf $folder.tgz .
    fi
done
