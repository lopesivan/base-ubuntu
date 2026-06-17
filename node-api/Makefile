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

exec:
	$(DOCKER) exec -it $(CONTAINER_NAME) bash

exec-root:
	$(DOCKER) exec -it -u root $(CONTAINER_NAME) bash

restart:
	$(DOCKER) restart $(CONTAINER_NAME)

clean: down
	$(DOCKER) rmi $(IMAGE):$(TAG)

# Testes rápidos via curl
test-health:
	curl -s http://localhost:3000/health | python3 -m json.tool

test-create:
	curl -s -X POST http://localhost:3000/items \
		-H "Content-Type: application/json" \
		-d '{"name":"teste","value":"123"}' | python3 -m json.tool

test-list:
	curl -s http://localhost:3000/items | python3 -m json.tool


ps:
	$(DOCKER) ps -a

status:
	$(DOCKER) stats --all --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

pause:
	$(DOCKER) $@ $(CONTAINER_NAME)
unpause:
	$(DOCKER) $@ $(CONTAINER_NAME)

images:
	$(DOCKER) images --format "{{.Repository}}:{{.Tag}}"| sort
ls:
	$(DOCKER) images --format "{{.ID}}: {{.Repository}}"
size:
	$(DOCKER) images --format "{{.Size}}\t: {{.Repository}}"
tags:
	$(DOCKER) images --format "{{.Tag}}\t: {{.Repository}}"| sort -t ':' -k2 -n

net:
	$(DOCKER) network ls

rm-network:
	$(DOCKER) network ls| awk '$$2 !~ "(bridge|host|none)" {print "docker network rm " $$1}' | sed '1d'

rmi: disable-x
	docker rmi ${MACHINENAME}:${META_TAG}

rm-all:
	$(DOCKER) ps -aq -f status=exited| xargs $(DOCKER) rm

stop-all:
	$(DOCKER) ps -aq -f status=running| xargs $(DOCKER) stop

log:
	$(DOCKER) logs -f $(CONTAINER_NAME)

ip:
	$(DOCKER) ps -q \
	| xargs $(DOCKER) inspect --format '{{ .Name }}:{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'\
	| \sed 's/^.*://'

memory:
	$(DOCKER) inspect `$(DOCKER) ps -aq` | grep -i mem

fix:
	$(DOCKER) images -q --filter "dangling=true"| xargs $(DOCKER) rmi -f

stop:
	$(DOCKER) stop $(CONTAINER_NAME)

rm:
	$(DOCKER) rm $(CONTAINER_NAME)


