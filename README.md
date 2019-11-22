# wine-runner-sc

This code is for building a bi-arch wine runner (i.e. lutris compatible) from ubuntu containers off of any provided wine tag/branch applying the patches in the patches folder.

It is currently aimed at Star Citizen support.

## Prerequisites

1) Install docker. This is often in your package management system.

2) Ensure you're in the docker group, e.g. `usermod -a -G docker yourusername`. User group changes usually require a logout/login to apply.

3) (Optional) Install `pigz` for faster packaging if you need it.

## Usage

- Add any patches you require into the `patches` folder.
- You can set `docker_args` for any additional docker build parameters you wish to set.
- The Dockerfile handles `http_proxy` during the build if you should want to cache packages. e.g. `export docker_args='--build-arg http_proxy=http://127.0.0.1:3128'`
- If you want the (sizeable) dangling images and produced image removed after completion, use `export do_prune=yes`. (This will remove _all_ dangling images).

```
export wine_version=4.20 # or your preferred version

./build.sh
```

This will produce a `build` folder with the compiled runner in it. It'll take some time even on a relatively powerful machine.

If you did set `do_prune` it'll prune dangling images and remove the now uneeded container.

You can use that runner directly (you could copy the runner subfolder to ~/.local/share/lutris/runners/wine/) or even package it up.

# Copyright etc

All copyrights and trademarks belong to their respective owners.

The code in this repository is freely available for anyone to use or modify without any restriction, though no warranty or suitability or fitness for any use is given.
