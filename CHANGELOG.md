## 0.2.0

Breaking changes:

  - `@Command` metadata must now be placed on the unnamed constructor instead 
    of the class.
  - `allowedHelp` in `Option` is now merged into `allowed`.

Features:

  - Add support for option argument parsers (#5)
  - Add support for hierarchical sub-commands (#15)
