include .version

NAME        = git-server-simple
USER        = $(shell id -u -n)
GROUP       = $(shell id -g -n)
UID         = $(shell id -u)
GID         = $(shell id -g)
GITHUB_USER = ivancarlos

VERSION     = $(MAJOR).$(MINOR).$(PATCH)
OWNER       = $(GITHUB_USER)
MACHINENAME = $(OWNER)/$(NAME)

DOCKER         = docker
CONTAINER_NAME = $(NAME)
IMAGE          = $(MACHINENAME)
META_TAG       = amd64-$(VERSION)

GITHUB_DATE = $(shell date "+%Y%m%d")
COMMIT_SHA  = $(shell git rev-parse --verify HEAD 2>/dev/null || echo "unknown")
SITE        = $(shell git config user.site 2>/dev/null || echo "ivanlopes.eng.br")

EXT_RELEASE_CLEAN = $(MINOR)
LS_TAG_NUMBER     = $(PATCH)

##############################################################################

# /home/$USER montado do host — repos ficam em ./home/$USER/repos
VOLUMES = \
    -v $(PWD)/home:/home/$(USER)

ENV_VARS = \
    -e USER=$(USER)   \
    -e GROUP=$(GROUP) \
    -e PUID=$(UID)    \
    -e PGID=$(GID)

BUILD_LABEL = \
    --label "org.opencontainers.image.created=$(GITHUB_DATE)"                      \
    --label "org.opencontainers.image.authors=$(SITE)"                             \
    --label "org.opencontainers.image.version=$(EXT_RELEASE_CLEAN)-ls$(LS_TAG_NUMBER)" \
    --label "org.opencontainers.image.revision=$(COMMIT_SHA)"                      \
    --label "org.opencontainers.image.title=git-server-simple"                     \
    --label "org.opencontainers.image.description=SSH + git-daemon on s6"

BUILD_OPTS = $(BUILD_LABEL) \
    -t $(IMAGE):$(META_TAG) \
    --build-arg VERSION="$(VERSION)" \
    --build-arg BUILD_DATE="$(GITHUB_DATE)"

##############################################################################

all: status

init-dirs:
	mkdir -p home/$(USER)/repos

# --- build ------------------------------------------------------------------
build: enable-x
	make -C system/su-exec
	$(DOCKER) build $(BUILD_OPTS) .

# --- run / up ---------------------------------------------------------------
up: init-dirs
	$(DOCKER) run -d        \
		--name $(CONTAINER_NAME) \
		--hostname $(NAME)       \
		-p 2222:22               \
		-p 9418:9418             \
		$(ENV_VARS)              \
		$(VOLUMES)               \
		$(IMAGE):$(META_TAG)

run: init-dirs
	$(DOCKER) run -it --rm  \
		--name $(CONTAINER_NAME) \
		--hostname $(NAME)       \
		-p 2222:22               \
		-p 9418:9418             \
		-e USER=$$(id -u -n)     \
		-e GROUP=$$(id -g -n)    \
		-e PUID=$$(id -u)        \
		-e PGID=$$(id -g)        \
		$(VOLUMES)               \
		$(IMAGE):$(META_TAG)

run-as-root: init-dirs
	$(DOCKER) run -it --rm       \
		--name $(CONTAINER_NAME)-root \
		--hostname $(NAME)            \
		-u root                       \
		-v $(PWD):/host               \
		$(VOLUMES)                    \
		-w /host                      \
		$(IMAGE):$(META_TAG)

# --- exec -------------------------------------------------------------------
exec:
	$(DOCKER) exec -it $(CONTAINER_NAME) /bin/bash -l

exec-root:
	$(DOCKER) exec -it -u root $(CONTAINER_NAME) bash

# --- repos ------------------------------------------------------------------
# Cria um bare repo pronto para SSH e git-daemon
# Uso: make new-repo REPO=meu-projeto
new-repo:
	@test -n "$(REPO)" || (echo "uso: make new-repo REPO=nome" && exit 1)
	$(DOCKER) exec -it -u $(USER) $(CONTAINER_NAME) \
		bash -c 'git init --bare ~/repos/$(REPO).git && \
		         touch ~/repos/$(REPO).git/git-daemon-export-ok && \
		         echo "$(REPO).git criado"'

# Lista repos no container
list-repos:
	$(DOCKER) exec $(CONTAINER_NAME) \
		bash -c 'ls -1 /srv/git/*.git 2>/dev/null || echo "(nenhum repo ainda)"'

# Adiciona chave pública ao authorized_keys do usuário
# Uso: make add-key KEY="ssh-ed25519 AAAA..."
add-key:
	@test -n "$(KEY)" || (echo "uso: make add-key KEY=\"ssh-ed25519 ...\"" && exit 1)
	$(DOCKER) exec $(CONTAINER_NAME) \
		bash -c 'echo "$(KEY)" >> /home/$(USER)/.ssh/authorized_keys && echo "chave adicionada"'

# --- ciclo de vida ----------------------------------------------------------
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
	$(DOCKER) rmi $(IMAGE):$(META_TAG)
	make -C system/su-exec clean

rmi: disable-x

# --- permissões -------------------------------------------------------------
SCRIPTS = \
    system/entrypoint.sh                          \
    system/root/usr/bin/with-contenv              \
    system/root/etc/cont-init.d/01-envfile        \
    system/root/etc/cont-init.d/10-adduser        \
    system/root/etc/cont-init.d/20-sshd           \
    system/root/etc/cont-init.d/30-git            \
    system/root/etc/cont-init.d/90-custom-folders \
    system/root/etc/cont-init.d/99-custom-scripts \
    system/root/etc/services.d/sshd/run           \
    system/root/etc/services.d/git-daemon/run

enable-x:
	chmod +x $(SCRIPTS)

disable-x:
	chmod -x $(SCRIPTS)

# eof
