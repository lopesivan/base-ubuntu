exec-python:
	$(DOCKER) exec -it $(CONTAINER_NAME) as-user python3
exec:
	$(DOCKER) exec -it $(CONTAINER_NAME) as-user bash -l
exec-root:
	$(DOCKER) exec -it -u root $(CONTAINER_NAME) bash
