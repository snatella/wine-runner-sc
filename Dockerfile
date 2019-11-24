FROM ubuntu:19.10 AS BUILD64
ARG build_cores=10
ARG wine_repo="https://github.com/wine-mirror/wine.git"
ARG wine_branchprefix="wine-"
ARG wine_version="4.20"
ARG do_wine_staging="yes"
ARG wine_staging_version="a9639c412f1b01dbaa931531d95611881d6ff2bf"
ARG http_proxy
ENV http_proxy=${http_proxy}
ENV https_proxy=${http_proxy}

RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install git -y \
    && dpkg --add-architecture i386 \
    && apt-get build-dep wine -y \
    && apt-get build-dep wine-development -y

WORKDIR /root

RUN git config --global http.proxy $http_proxy && git clone --depth 1 --branch ${wine_branchprefix}${wine_version} ${wine_repo} ~/wine-git

COPY patches patches/
COPY patcher.sh patcher.sh

RUN chmod +x patcher.sh && ./patcher.sh "${do_wine_staging}" "${wine_staging_version}"

RUN mkdir $HOME/wine64 \
    && mkdir $HOME/wine \
    && cd $HOME/wine64 \
    && ../wine-git/configure --enable-win64 --prefix=/root/wine-build-64/ \
    && make -j${build_cores} install

FROM i386/ubuntu:19.10 AS BUILD32
ARG build_cores=10
ARG http_proxy
ENV http_proxy=${http_proxy}
ENV https_proxy=${http_proxy}

RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install git -y \
    && apt-get build-dep wine -y \
    && apt-get build-dep wine-development -y

WORKDIR /root

COPY --from=BUILD64 /root/wine-git /root/wine-git
COPY --from=BUILD64 /root/wine64 /root/wine64
COPY --from=BUILD64 /root/wine-build-64/ /root/wine-build-64/

RUN mkdir $HOME/wine32-tools \
    && cd $HOME/wine32-tools \
    && ~/wine-git/configure  --prefix=/root/wine-build-32/ \
    && make -j${build_cores} install

RUN mkdir $HOME/wine32 \
    && cd $HOME/wine32 \
    && ~/wine-git/configure --with-wine64=$HOME/wine64 --with-wine-tools=$HOME/wine32-tools --prefix=/root/wine-build-32/ \
    && make -j${build_cores} install
