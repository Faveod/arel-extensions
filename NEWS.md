# News

- MS SQL: restrict date-quoting to Arel <= 6 (Rails 4.2)

## Release v2.1.11/v1.3.11

- MS SQL: turn on warnings on requires only when necessary.

## Release v2.1.10/v1.3.10

- MS SQL: add support for jruby 9.4 via [activerecord-jdbc-alt-adapter](https://rubygems.org/gems/activerecord-jdbc-alt-adapter/)

## Release v2.1.9/v1.3.9

### Bug Fixes

- Postgres:
  - Datetime formatting in postgres now behaves like mysql: if the target
    timezone is a string, we automatically consider that you're trying to
    convert from `UTC`.
  - Datetime casting will now automatically ask for a
    `timestamp without timezone`, also aligning with the expected befavior
    in mysql. This also makes casting work better with timezone conversion,
    especially if you don't pass the timezone from which you're converting
    to.
    ```ruby
    scope
      .select(Arel.quoted('2022-02-01 10:42:00')
      .cast(:datetime)
      .format_date('%Y/%m/%d %H:%M:%S', 'Europe/Paris')
      .as('res'))
    ```
    Will produce:
    ```sql
    SELECT TO_CHAR(
        CAST('2022-02-01 10:42:00' AS timestamp without time zone) AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris',
        'YYYY/MM/DD HH24:MI:SS'
      )
      AS "res"
    -- …
    ```

## Release v2.1.7/v1.3.7

### New Features

- `o.format_date` as an alternative to `o.format`
  The actual behavior of `format` is inconsistent across DB vendors: in mysql we
  can format dates and numbers with it, and in the other ones we only format
  dates.

  We're planning on normalizing this behavior. We want `format` to "cleverly"
  format dates or numbers, and `format_date` / `format_number` to strictly
  format dates / numbers.

  The introduction of `format_date` is the first step in this direction.

## Release v2.1.6/v1.3.6

### Bug Fixes

- This used to fail.
  ```
  Arel.when(a).then(b).format('%Y-%m-%d')
  ```

### New Features

- `o.present`, a synonym for `o.not_blank`
- `o.coalesce_blank(a, b, c)`
- `o.if_present`, if the value is `null` or blank, then it returns `null`,
  otherwise, it returns the value.  Inspired by rails' `presence`.
