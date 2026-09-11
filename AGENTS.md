# AGENTS.md

Arel Extensions is a Ruby gem that monkey-patches Arel/ActiveRecord to add SQL functions and operator shortcuts across MySQL, PostgreSQL, SQLite, Oracle, MSSQL, and DB2. The test matrix runs on GitHub Actions (`.github/workflows/ruby.yml`) and Docker, not on a host Ruby.

## Versioning: this repo builds TWO gems from one tree

- `version_v1.rb` + `gemspecs/arel_extensions-v1.gemspec` → v1.x (Rails 5.2 / Arel 6)
- `version_v2.rb` + `gemspecs/arel_extensions-v2.gemspec` → v2.x (Rails 6+ / `activerecord >= 6.0`)

`bin/build` and CI copy these over the working files (`lib/arel_extensions/version.rb`, root `arel_extensions.gemspec`). So:

## Picking a Rails version (the Gemfile is generated per Rails version)

There is no single Gemfile for all work. Pick one, then `bundle install`:

```sh
make local-rails8_1      # maps to gemfiles/rails8_1.gemfile (dots -> underscores: make local-rails8_1 for rails8_1)
bundle install
```

`make clean` removes `.bundle`, `Gemfile.lock`, `vendor`.

## Testing

- DBs are provided by `dev/compose.yaml`. `make up` starts them, `make shell` execs into the `arelx` container (gems preinstalled there).
- You always go through the docker containers by doing the `make shell` to jump into the deve env, and never test anything on the host machine.
- Fastest feedback (no DB needed): `bundle exec rake test:to_sql` (alias: `rake test:sql`). Tests live in `test/visitors/test_to_sql.rb`. But this is an informative SQL target. The ture ones are those of vendors.
- Per-DB integration tests require a running DB and are gated by `ENV['DB']`:
  `bundle exec rake test:{mysql,postgresql,sqlite,ibm_db,oracle,mssql}` (shorthands `test:pg`/`test:postgres`).
  You always test against real DBs, and always through the docker compose provided. Never install anything on the host machine unless instructed to explicitly to do so. You can use docker to simulate certain configurations (e.g. a certain linux distro, a certain version of a certain DBMS vendor, etc...).
- Real-DB tests (in `test/with_ar/`) read `test/database.yml` (ERB-rendered) and honor `MYSQL_HOST`/`POSTGRES_HOST`/`MSSQL_HOST` env vars. Credentials are hardcoded there (root/secret/Password12!).
- Only load ONE DB adapter gem per test run. Loading several backends at once makes the wrong visitor win and breaks assertions (see comment in `test/arelx_test_helper.rb`).

## Lint

```sh
make lint      # bundle exec rubocop --config .rubocop.yml --require rubocop-performance
make lint-fix  # same with -a (autocorrect)
```

`test/**/*`, `vendor`, and `dev` are excluded from rubocop. Target Ruby is 2.7; style is deliberately non-default (see `.rubocop.yml`).

But dont run any linting, the repo is not ready yet.

## Architecture notes

- Per-DB SQL rendering lives in `lib/arel_extensions/visitors/` (`mysql.rb`, `postgresql.rb`, `mssql.rb`, `oracle.rb`, `ibm_db.rb`, `sqlite.rb`, `to_sql.rb`). When adding a function that maps to different SQL per DB, update each visitor plus the README table.
- `ArelExtensions::CommonSqlFunctions#add_sql_functions` executes vendor SQL from `init/<db>.sql` (mssql batches split on `GO`; mysql on `$$`). Keep new DB-side functions there.
- Feature list and per-vendor support matrix are maintained in `README.md` (big table) — update it alongside code changes.

## Committing

Never commit. If you do edits that are worthy of a commit, you only suggest a non-verbose, succint commit message, following the style of this repo.

## Ruby style

The goal is to support the minimum ruby supported by this gem, and it's Ruby 2.7 for now. This repository tries to simplify the use of the ruby language, so there are certain things that are avoided because they have alternatives, and these alternatives are more "universal" (i.e. exist in many programming languages too), therefore:

1. Avoid `unless`, and `until`. 
1. `each` blocks are always delimited by `do`/`end`, as for other iteration primitives like `map`, `select`, etc, you always use braces `{ ... }`.
1. Avoid early returns in functions.
