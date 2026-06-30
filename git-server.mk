REPO ?= teste.git

git-clone:
	git clone git://localhost:9418/$(REPO)

git-info:
	$(DOCKER) exec -it $(CONTAINER_NAME) ls -l /srv/git
	$(DOCKER) exec -it $(CONTAINER_NAME) ls -l /srv/git/$(REPO)
	$(DOCKER) exec -it $(CONTAINER_NAME) ls -l /srv/git/$(REPO)/git-daemon-export-ok
	$(DOCKER) exec -it $(CONTAINER_NAME) git --git-dir=/srv/git/$(REPO) config --list

new-repo:
	# USAGE:
	# make new-repo REPO=meu-projeto.git
	# make git-clone REPO=meu-projeto.git
	#
	@if [ -d "repos/$(REPO)" ]; then \
		echo "[skip] repositório já existe: repos/$(REPO)"; \
	else \
		echo "[new] criando repos/$(REPO)"; \
		mkdir -p repos; \
		git init --bare "repos/$(REPO)"; \
		touch "repos/$(REPO)/git-daemon-export-ok"; \
		git --git-dir="repos/$(REPO)" config daemon.receivepack true; \
		echo "[ok] repositório criado: git://localhost:9418/$(REPO)"; \
	fi

git-test: new-repo git-info

git-list:
	# USAGE:
	# make git-list
	# make git-list REPO=projeto.git
	#
	@$(DOCKER) exec -it $(CONTAINER_NAME) bash -lc '\
		REPO="$(REPO)"; \
		echo "=== $$REPO ==="; \
		echo; \
		echo "[/srv/git]"; \
		ls -la /srv/git; \
		echo; \
		echo "[repositorio]"; \
		ls -la "/srv/git/$$REPO" || true; \
		echo; \
		echo "[config]"; \
		cat "/srv/git/$$REPO/config" || true; \
		echo; \
		echo "[git config]"; \
		git --git-dir="/srv/git/$$REPO" config --list || true; \
		echo; \
		echo "[export]"; \
		ls -l "/srv/git/$$REPO/git-daemon-export-ok" || true'
