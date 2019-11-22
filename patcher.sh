#!/bin/bash

set -e

cd $HOME/wine-git

for file in $(ls ../patches/); do
    echo "Applying $file"
    patch -l -p1 <../patches/$file
done

echo "Done patching"
