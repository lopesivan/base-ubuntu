exec-python:
	$(DOCKER_COMPOSE) exec $(CONTAINER_NAME) as-user python3
exec:
	$(DOCKER_COMPOSE) exec $(CONTAINER_NAME) as-user bash -l
exec-root:
	$(DOCKER) exec -it -u root $(CONTAINER_NAME) bash
