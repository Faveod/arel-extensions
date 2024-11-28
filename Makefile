all: test

clean:
	rm -rf .vendor .bundle Gemfile.lock vendor

install:
	bundle install

lint:
	bundle exec rubocop --config .rubocop.yml

publish:
	./bin/publish

test:
	bundle exec rake test

.PHONY: all test install lint publish clean
