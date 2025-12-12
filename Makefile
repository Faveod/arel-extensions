COMPOSE_FILE := dev/compose.yaml
DC := docker compose -f $(COMPOSE_FILE)

.PHONY: down rebuild shell up

down:
	$(DC) down

rebuild:
	$(DC) build --no-cache

# Jump into the container
shell: up
	$(DC) exec arelx bash

# Boot everything and keep it running (daemon mode)
up:
	$(DC) up -d
