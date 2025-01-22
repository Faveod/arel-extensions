all: clean install

clean:
	rm -rf .bundle Gemfile.lock vendor

install:
	bundle install

lint:
	bundle exec rubocop --config .rubocop.yml --require rubocop-performance

lint-fix:
	bundle exec rubocop --config .rubocop.yml -A

publish:
	./bin/publish

.PHONY: all clean install lint publish
