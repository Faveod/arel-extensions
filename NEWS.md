# News

## Current Release

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
