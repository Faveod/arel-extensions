COMPOSE_FILE := dev/compose.yaml
DC := docker compose -f $(COMPOSE_FILE)

.PHONY: all clean down install lint publish rebuild shell test up

all: clean install

clean:
	rm -rf .bundle Gemfile.lock vendor

down:
	$(DC) down

install:
	bundle install

lint:
	bundle exec rubocop --config .rubocop.yml --require rubocop-performance

lint-fix:
	bundle exec rubocop --config .rubocop.yml -a

local-%:
	@version="$*"; \
	file="gemfiles/rails$${version//./_}.gemfile"; \
	if [ ! -f "$$file" ]; then \
		echo "No such Gemfile: $$file"; \
		exit 1; \
	fi; \
	echo "Using $$file"; \
	bundle config set --local gemfile "$$file"

publish:
	./bin/publish

rebuild:
	$(DC) build --no-cache

# Jump into the container
shell: up
	$(DC) exec arelx bash

test:
	bundle exec rake test

# Boot everything and keep it running (daemon mode)
up:
	$(DC) up -d
