include .version

# Dado um número de versão MAJOR.MINOR.PATCH, incremente a:

# 1. versão Maior(MAJOR): quando fizer mudanças incompatíveis na API,
# 2. versão Menor(MINOR): quando adicionar funcionalidades mantendo
#    compatibilidade, e
# 3. versão de Correção(PATCH): quando corrigir falhas mantendo compatibilidade.
#    Rótulos adicionais para pré-lançamento(pre-release) e metadados de
#    construção(build) estão disponíveis como extensão ao formato
#    MAJOR.MINOR.PATCH.

NAME              = xpto-server
USER              = $(shell id -u -n)
GROUP             = $(shell id -g -n)
UID               = $(shell id -u)
GID               = $(shell id -g)
env-file          = env.production
GITHUB_USER       = ivancarlos

VERSION           = $(MAJOR).$(MINOR).$(PATCH)
SERVICE           = ${NAME}
OWNER             = ${GITHUB_USER}
MACHINENAME       = $(OWNER)/$(NAME)

DOCKER_COMPOSE    = docker-compose --env-file ${env-file}
DOCKER            = docker
CONTAINER_NAME    = $(NAME)
EMAIL             = $(shell git config user.email)

LATEST            = $(VERSION)
GITHUB_DATE       = $(shell date "+%Y%m%d")

COMMIT_SHA        = $(shell git rev-parse --verify HEAD 2>/dev/null || echo "unknown")
SITE              = $(shell git config user.site 2>/dev/null || echo "ivanlopes.eng.br")

EXT_RELEASE_CLEAN = $(MINOR)
LS_TAG_NUMBER     = $(PATCH)

IMAGE             = ${MACHINENAME}
META_TAG          = amd64-${VERSION}
VERSION_TAG       = ${LATEST}

##############################################################################

VOLUMES = -v `pwd`/system/root/etc/cont-init.d:/etc/cont-init.d \
		  -v `pwd`/system/opt/sdk:/opt/sdk \
          -v `pwd`/system/var/sdk:/var/sdk \
          -v `pwd`/system/etc/sdk:/etc/sdk

BUILD_LABEL       = \
	--label "org.opencontainers.image.created=${GITHUB_DATE}" \
	--label "org.opencontainers.image.authors=${SITE}" \
	--label "org.opencontainers.image.url=https://github.com/${GITHUB_USER}/docker-baseimage-ubuntu/packages" \
	--label "org.opencontainers.image.documentation=https://docs.${SITE}/images/docker-baseimage-ubuntu" \
	--label "org.opencontainers.image.source=https://github.com/${GITHUB_USER}/docker-baseimage-ubuntu" \
	--label "org.opencontainers.image.version=${EXT_RELEASE_CLEAN}-ls${LS_TAG_NUMBER}" \
	--label "org.opencontainers.image.revision=${COMMIT_SHA}" \
	--label "org.opencontainers.image.vendor=${SITE}" \
	--label "org.opencontainers.image.licenses=GPL-3.0-only" \
	--label "org.opencontainers.image.ref.name=${COMMIT_SHA}" \
	--label "org.opencontainers.image.title=Baseimage-ubuntu" \
	--label "org.opencontainers.image.description=baseimage-ubuntu image by $(shell git config user.name)"

#BUILD_OPTS = $(BUILD_LABEL) --no-cache --pull -t ${IMAGE}:${META_TAG} --build-arg VERSION="${VERSION_TAG}" --build-arg BUILD_DATE=${GITHUB_DATE}
BUILD_OPTS = $(BUILD_LABEL) -t ${IMAGE}:${META_TAG} --build-arg VERSION="${VERSION_TAG}" --build-arg BUILD_DATE=${GITHUB_DATE}

all: status

init:
	sudo chown ${USER}:${USER} -R system/

config:
	# Configure envireoment file ${env-file}
	@echo META_TAG=$(META_TAG)              > ${env-file}
	@echo IMAGE=$(IMAGE)                   >> ${env-file}
	@echo CONTAINER_NAME=$(CONTAINER_NAME) >> ${env-file}
	@echo HOSTNAME=${NAME}                 >> ${env-file}
	@echo SERVICE=${SERVICE}               >> ${env-file}
	@echo USER=${USER}                     >> ${env-file}
	@echo GROUP=${GROUP}                   >> ${env-file}
	@echo UID=${UID}                       >> ${env-file}
	@echo GID=${GID}                       >> ${env-file}
	$(DOCKER_COMPOSE) config

disable-x:
	chmod -x system/opt/sdk/bin/sdk.sh \
	system/entrypoint.sh \
	system/root/usr/bin/with-contenv \
	system/root/etc/cont-init.d/90-custom-folders \
	system/root/etc/cont-init.d/99-custom-scripts \
	system/root/etc/cont-init.d/01-envfile \
	system/root/etc/cont-init.d/10-adduser

enable-x:
	chmod +x system/opt/sdk/bin/sdk.sh \
	system/entrypoint.sh \
	system/root/usr/bin/with-contenv \
	system/root/etc/cont-init.d/90-custom-folders \
	system/root/etc/cont-init.d/99-custom-scripts \
	system/root/etc/cont-init.d/01-envfile \
	system/root/etc/cont-init.d/10-adduser

build: su-exec enable-x
	$(DOCKER) build $(BUILD_OPTS) .

up: config
	$(DOCKER_COMPOSE) up -d ${SERVICE}

down:
	$(COMPOSE) down

# Tools
include tools.mk

run: config
	# create user ${USER}
	$(DOCKER_COMPOSE) run --rm \
		--name ${NAME} \
		-e USER=$$(id -u -n) \
		-e GROUP=$$(id -g -n) \
		-e UID=$$(id -u) \
		-e GID=$$(id -g) \
		${VOLUMES} \
		-w/home/$$(id -u -n) \
		${SERVICE}

exec:
	$(DOCKER_COMPOSE) exec $(CONTAINER_NAME) entrypoint.sh /bin/bash -l

exec-root:
	$(DOCKER) exec -it -u root $(CONTAINER_NAME) bash

su-exec:
	make -C system/su-exec

clean-su-exec:
	make -C system/su-exec clean
create-dirs:
	mkdir opt

rm-dirs:
	sudo rm -rf opt

reset: rm-dirs create-dirs

# eof
