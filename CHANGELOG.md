## 0.3.2

Bugfixes:

  - dart:mirror closurization operator removed (#50)

## 0.3.0

Features:

  - Demo: complete *nix `cat` implementation (#28)
  - Derive parsers from type annotations (#31)
  - Derive rest parameter from List type annotation (#36)
  - Derive allowMultiple from List type annotation (#34)
  - Add ellipsis to rest parameter help formatting (#22)
  - Include script name in error messages (#32)
  - Input and output parsers which transparently handle both file paths and '-' 
    for stdin/stdout (#23)
  
Breaking changes:

  - Renamed `sketch` to `declare` (#37)
  - Rest.min changed to Rest.required (#26)
  - Flag.negatable now defaults to false (#25)

## 0.2.0

Features:

  - Support argument parsers (#5)
  - Support hierarchical sub-commands (#15)

Breaking changes:

  - `@Command` metadata must now be placed on the unnamed constructor instead 
    of the class.
  - `allowedHelp` in `Option` is now merged into `allowed`.
  