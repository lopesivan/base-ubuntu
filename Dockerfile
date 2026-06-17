FROM ubuntu:22.04

ARG BUILD_DATE
ARG VERSION
ARG S6_OVERLAY_VERSION="3.1.6.2"
ARG TARGETARCH="amd64"

LABEL build_version="ivanlopes.eng.br version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="Ivan Lopes <lopesivan.ufrj@gmail.com>"

ENV DEBIAN_FRONTEND="noninteractive" \
    HOME="/root"                      \
    LANGUAGE="en_US.UTF-8"            \
    LANG="en_US.UTF-8"                \
    TERM="xterm"                      \
    S6_BEHAVIOUR_IF_STAGE2_ABORTS="2" \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0"

# s6-overlay v3: dois tarballs (binários + symlinks de noarch)
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz   /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz  /tmp/

RUN set -eux && \
    # política de init para apt dentro de container
    echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d && \
    # limpeza de cache agressiva
    echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' \
        > /etc/apt/apt.conf.d/docker-clean && \
    echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' \
        >> /etc/apt/apt.conf.d/docker-clean && \
    echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' \
        >> /etc/apt/apt.conf.d/docker-clean && \
    echo 'Acquire::Languages "none";'                          > /etc/apt/apt.conf.d/docker-no-languages && \
    echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' \
        > /etc/apt/apt.conf.d/docker-gzip-indexes && \
    # instala pacotes base
    apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-utils   \
        ca-certificates \
        curl        \
        locales     \
        tzdata      \
        xz-utils    \
    && \
    locale-gen en_US.UTF-8 && \
    # instala s6-overlay v3
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz  && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz  && \
    # cleanup
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# su-exec compilado estaticamente
COPY system/su-exec/su-exec /usr/local/bin/su-exec

# scripts de sistema
COPY system/entrypoint.sh             /usr/local/bin/entrypoint.sh
COPY system/root/usr/bin/with-contenv /usr/bin/with-contenv
COPY system/root/etc/cont-init.d/     /etc/s6-overlay/s6-rc.d/
COPY system/opt/sdk/                  /opt/sdk/
COPY system/etc/sdk/                  /etc/sdk/

RUN chmod +x \
        /etc/s6-overlay/s6-rc.d/* \
        /usr/local/bin/entrypoint.sh \
        /usr/local/bin/su-exec       \
        /usr/bin/with-contenv

ENTRYPOINT ["/init"]

###
