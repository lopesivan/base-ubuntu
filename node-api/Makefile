NAME           = node-api
CONTAINER_NAME = node-api
IMAGE          = ivancarlos/$(NAME)
TAG            = latest
DOCKER         = docker
COMPOSE        = docker-compose

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

