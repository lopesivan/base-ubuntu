


test:
	curl http://localhost:8989/


clone:
	git clone git://localhost:9418/teste.git

repo:
	mkdir -p repos
	git init --bare repos/teste.git
	touch repos/teste.git/git-daemon-export-ok
	git --git-dir=repos/teste.git config daemon.receivepack true

git-info:
	$(DOCKER) exec -it $(CONTAINER_NAME) ls -l /srv/git
	$(DOCKER) exec -it $(CONTAINER_NAME) ls -l /srv/git/teste.git
	$(DOCKER) exec -it $(CONTAINER_NAME) ls -l /srv/git/teste.git/git-daemon-export-ok

git-list:
	$(DOCKER) exec -it $(CONTAINER_NAME) bash -lc '
	echo "--- /srv/git ---"
	ls -la /srv/git

	echo "--- teste.git ---"
	ls -la /srv/git/teste.git || true

	echo "--- config ---"
	cat /srv/git/teste.git/config || true

	echo "--- daemon marker ---"
	ls -la /srv/git/teste.git/git-daemon-export-ok || true
	'
