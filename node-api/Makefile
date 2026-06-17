include ../.version

NAME              = node-api
USER              = $(shell id -u -n)
GROUP             = $(shell id -g -n)
UID               = $(shell id -u)
GID               = $(shell id -g)
env-file          =
GITHUB_USER       = ivancarlos

VERSION           = $(MAJOR).$(MINOR).$(PATCH)
SERVICE           = ${NAME}
OWNER             = ${GITHUB_USER}
MACHINENAME       = $(OWNER)/$(NAME)

DOCKER_COMPOSE    = docker-compose
DOCKER            = docker
CONTAINER_NAME    = $(NAME)
EMAIL             = $(shell git config user.email)

LATEST            = $(VERSION)
GITHUB_DATE       = $(shell date "+%Y%m%d")

COMMIT_SHA        = $(shell git rev-parse --verify HEAD 2>/dev/null || echo "unknown")
SITE              = $(shell git config user.site 2>/dev/null || echo "ivanlopes.eng.br")

EXT_RELEASE_CLEAN = $(MINOR)
LS_TAG_NUMBER     = $(PATCH)

LATEST            = latest
IMAGE             = ${MACHINENAME}
META_TAG          = ${LATEST}
VERSION_TAG       = ${LATEST}

all: build

disable-x:
	chmod -x \
	system/root/etc/cont-init.d/50-api-init \
	system/services.d/node-api/run

enable-x:
	chmod +x \
	system/root/etc/cont-init.d/50-api-init \
	system/services.d/node-api/run

build: enable-x
	$(DOCKER) build -t $(IMAGE):$(TAG) .

up:
	mkdir -p config
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

# Tools
include ../tools.mk

exec:
	$(DOCKER) exec -it $(CONTAINER_NAME) bash

exec-root:
	$(DOCKER) exec -it -u root $(CONTAINER_NAME) bash

# Testes rápidos via curl
test-health:
	curl -s http://localhost:3000/health | python3 -m json.tool

test-create:
	curl -s -X POST http://localhost:3000/items \
		-H "Content-Type: application/json" \
		-d '{"name":"teste","value":"123"}' | python3 -m json.tool

test-list:
	curl -s http://localhost:3000/items | python3 -m json.tool

