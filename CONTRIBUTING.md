# Contributing

Your PRs are welcome.

## Local Development

Let's say you want to develop/test for `ruby 2.7.5` and `rails 5.2`.

You will need to fix your ruby version:

```bash
rbenv install 2.7.5
rbenv local 2.7.5
```

Fix your gemfiles:

```bash
bundle config set --local gemfile ./gemfiles/rails6.gemfile
cp gemspecs/arel_extensions-v2.gemspec arel_extensions.gemspec
```

Or by copying:

```bash
cp gemfiles/gemfiles/rails6.gemfile Gemfiles
cp gemspecs/arel_extensions-v2.gemspec arel_extensions.gemspec
```

Install dependencies:
```bash
bundle install
```

> [!IMPORTANT]
> Sometimes you might need to delete `vendor` dirs.
> If you use `bundle config set --local gemfile`, it will be in `gemfiles/vendor`.
> If you just `cp gemfiles/…`, it will be in `vendor`.

Develop, then test:

```bash
bundle exec rake test:to_sql
```

Refer to the [Version Compatibility](#version-compatibility) section to correctly
set your gemfile.

## Testing many DBs without installing them

We provide a `docker compose` to set up some databases for testing:

```bash
docker compose -f dev/compose.yaml up --exit-code-from arelx
```

Or simply call `bin/compose`.

The databases, versions of arelx, and versions of ruby are all read from the
matrixes defined in `.github/workflow/ruby.yml`. To test a specific
configuration, all you have to do is comment the versions you're not
insterested in.

> [!IMPORTANT]
> This methods conflicts with the [Local development](#local-development) method.
> If you find yourself jumping between both, make sure you delete `Gemfile.lock`
> and `vendor/`.

### VSCode

You can use the following `launch.json` to debug:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "rdbg",
      "name": "Debug DB",
      "request": "launch",
      "cwd": "${workspaceRoot}",
      "script": "test/with_ar/all_agnostic_test.rb",
      "command": "bundle exec ruby -Ilib -Itest",
      "env": {
        "DB": "postgresql"
      },
      "useBundler": false,
      "askParameters": false
    },
    {
      "type": "rdbg",
      "name": "Debug to_sql",
      "request": "launch",
      "cwd": "${workspaceRoot}",
      "script": "test/visitors/test_to_sql.rb",
      "command": "bundle exec ruby -Ilib -Itest",
      "useBundler": false,
      "askParameters": false
    }
  ]
}
```
