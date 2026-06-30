include .version

NAME        = git-server
USER        = $(shell id -u -n)
GROUP       = $(shell id -g -n)
UID         = $(shell id -u)
GID         = $(shell id -g)
GITHUB_USER = ivancarlos

VERSION     = $(MAJOR).$(MINOR).$(PATCH)
OWNER       = $(GITHUB_USER)
MACHINENAME = $(OWNER)/$(NAME)

DOCKER          = docker
CONTAINER_NAME  = $(NAME)
IMAGE           = $(MACHINENAME)
META_TAG        = amd64-$(VERSION)

GITHUB_DATE     = $(shell date "+%Y%m%d")
COMMIT_SHA      = $(shell git rev-parse --verify HEAD 2>/dev/null || echo "unknown")
SITE            = $(shell git config user.site 2>/dev/null || echo "ivanlopes.eng.br")

EXT_RELEASE_CLEAN = $(MINOR)
LS_TAG_NUMBER     = $(PATCH)

##############################################################################

VOLUMES = \
    -v $(PWD)/home:/home/$(USER)              \
    -v $(PWD)/data/gitea:/var/lib/gitea       \
    -v $(PWD)/config/gitea:/etc/gitea         \
    -v $(PWD)/system/root/etc/cont-init.d:/etc/s6-overlay/s6-rc.d

ENV_VARS = \
    -e USER=$(USER)   \
    -e GROUP=$(GROUP) \
    -e PUID=$(UID)    \
    -e PGID=$(GID)

BUILD_LABEL = \
    --label "org.opencontainers.image.created=$(GITHUB_DATE)"          \
    --label "org.opencontainers.image.authors=$(SITE)"                 \
    --label "org.opencontainers.image.version=$(EXT_RELEASE_CLEAN)-ls$(LS_TAG_NUMBER)" \
    --label "org.opencontainers.image.revision=$(COMMIT_SHA)"          \
    --label "org.opencontainers.image.title=git-server"                \
    --label "org.opencontainers.image.description=Gitea + sshd on s6"

BUILD_OPTS = $(BUILD_LABEL) \
    -t $(IMAGE):$(META_TAG) \
    --build-arg VERSION="$(VERSION)" \
    --build-arg BUILD_DATE="$(GITHUB_DATE)"

##############################################################################

all: status

# Garante que os volumes locais existam antes de subir
init-dirs:
	mkdir -p home data/gitea config/gitea

# Sobe em background
up: init-dirs
	$(DOCKER) run -d \
		--name $(CONTAINER_NAME) \
		--hostname $(NAME)       \
		-p 2222:22               \
		-p 3000:3000             \
		$(ENV_VARS)              \
		$(VOLUMES)               \
		$(IMAGE):$(META_TAG)

# Interativo efêmero (debug / primeiro boot)
run: init-dirs
	$(DOCKER) run -it --rm    \
		--name $(CONTAINER_NAME) \
		--hostname $(NAME)       \
		-p 2222:22               \
		-p 3000:3000             \
		-e USER=$$(id -u -n)     \
		-e GROUP=$$(id -g -n)    \
		-e PUID=$$(id -u)        \
		-e PGID=$$(id -g)        \
		$(VOLUMES)               \
		$(IMAGE):$(META_TAG)

# Interativo como root (diagnóstico)
run-as-root: init-dirs
	$(DOCKER) run -it --rm      \
		--name $(CONTAINER_NAME)-root \
		--hostname $(NAME)            \
		-u root                       \
		-v $(PWD):/host               \
		$(VOLUMES)                    \
		-w /host                      \
		$(IMAGE):$(META_TAG)

exec:
	$(DOCKER) exec -it $(CONTAINER_NAME) /bin/bash -l

exec-root:
	$(DOCKER) exec -it -u root $(CONTAINER_NAME) bash

# Abre shell como o usuário git dentro do container
exec-git:
	$(DOCKER) exec -it -u $(USER) $(CONTAINER_NAME) /bin/bash -l

build: enable-x
	$(DOCKER) build $(BUILD_OPTS) .

stop:
	$(DOCKER) stop $(CONTAINER_NAME)

rm:
	$(DOCKER) rm $(CONTAINER_NAME)

clean: stop rm

restart:
	$(DOCKER) restart $(CONTAINER_NAME)

log:
	$(DOCKER) logs -f $(CONTAINER_NAME)

status:
	$(DOCKER) stats --all --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

ps:
	$(DOCKER) ps -a

images:
	$(DOCKER) images --format "{{.Repository}}:{{.Tag}}" | sort

fix:
	$(DOCKER) images -q --filter "dangling=true" | xargs $(DOCKER) rmi -f

ip:
	$(DOCKER) ps -q \
	| xargs $(DOCKER) inspect \
	    --format '{{ .Name }}:{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
	| sed 's/^.*://'

enable-x:
	chmod +x \
		system/entrypoint.sh \
		system/root/usr/bin/with-contenv \
		system/root/etc/cont-init.d/01-envfile \
		system/root/etc/cont-init.d/10-adduser \
		system/root/etc/cont-init.d/20-sshd    \
		system/root/etc/cont-init.d/30-gitea   \
		system/root/etc/cont-init.d/90-custom-folders \
		system/root/etc/cont-init.d/99-custom-scripts \
		system/root/etc/services.d/sshd/run    \
		system/root/etc/services.d/gitea/run

disable-x:
	chmod -x \
		system/entrypoint.sh \
		system/root/usr/bin/with-contenv \
		system/root/etc/cont-init.d/01-envfile \
		system/root/etc/cont-init.d/10-adduser \
		system/root/etc/cont-init.d/20-sshd    \
		system/root/etc/cont-init.d/30-gitea   \
		system/root/etc/cont-init.d/90-custom-folders \
		system/root/etc/cont-init.d/99-custom-scripts \
		system/root/etc/services.d/sshd/run    \
		system/root/etc/services.d/gitea/run

rmi: disable-x
	$(DOCKER) rmi $(IMAGE):$(META_TAG)

# eof
