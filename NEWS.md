# Release

## Bug Fixes

- This used to fail.
  ```
  Arel.when(a).then(b).format('%Y-%m-%d')
  ```

## New Features

- `o.present`, a synonym for `o.not_blank`
- `o.coalesce_blank(a, b, c)`
- `o.if_present`, if the value is `null` or blank, then it returns `null`,
  otherwise, it returns the value.  Inspired by rails' `presence`.
