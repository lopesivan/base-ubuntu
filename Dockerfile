FROM ubuntu:22.04

ARG BUILD_DATE
ARG VERSION
ARG S6_OVERLAY_VERSION="3.1.6.2"
ARG GITEA_VERSION="1.22.3"
ARG TARGETARCH="amd64"

LABEL build_version="ivanlopes.eng.br version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="Ivan Lopes <lopesivan.ufrj@gmail.com>"

ENV DEBIAN_FRONTEND="noninteractive"        \
    HOME="/root"                             \
    LANGUAGE="en_US.UTF-8"                  \
    LANG="en_US.UTF-8"                      \
    TERM="xterm"                             \
    S6_BEHAVIOUR_IF_STAGE2_ABORTS="2"       \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0"    \
    GITEA_WORK_DIR="/var/lib/gitea"         \
    GITEA_CUSTOM="/etc/gitea"

# s6-overlay v3
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz  /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp/

# Gitea binary
ADD https://dl.gitea.com/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64 /usr/local/bin/gitea

RUN set -eux && \
    echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d && \
    echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' \
        > /etc/apt/apt.conf.d/docker-clean && \
    echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' \
        >> /etc/apt/apt.conf.d/docker-clean && \
    echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-utils       \
        ca-certificates \
        curl            \
        git             \
        locales         \
        openssh-server  \
        tzdata          \
        xz-utils        \
    && \
    locale-gen en_US.UTF-8 && \
    # s6-overlay
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz  && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz  && \
    # Gitea
    chmod +x /usr/local/bin/gitea && \
    # Diretórios do Gitea
    mkdir -p /var/lib/gitea/{custom,data,log} \
             /etc/gitea                        \
             /run/sshd                         && \
    chmod 750 /var/lib/gitea && \
    chmod 770 /etc/gitea     && \
    # cleanup
    apt-get autoremove -y && \
    apt-get clean         && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# su-exec estático
COPY system/su-exec/su-exec        /usr/local/bin/su-exec

# scripts base
COPY system/entrypoint.sh          /usr/local/bin/entrypoint.sh
COPY system/root/usr/bin/with-contenv  /usr/bin/with-contenv

# cont-init.d
COPY system/root/etc/cont-init.d/  /etc/s6-overlay/s6-rc.d/

# services.d — sshd e gitea
COPY system/root/etc/services.d/   /etc/services.d/

RUN chmod +x \
        /usr/local/bin/entrypoint.sh \
        /usr/local/bin/su-exec       \
        /usr/bin/with-contenv        \
        /etc/s6-overlay/s6-rc.d/*   \
        /etc/services.d/sshd/run    \
        /etc/services.d/gitea/run

EXPOSE 22 3000

ENTRYPOINT ["/init"]
