## Unreleased

  - Add `name` parameter to `Option` and `Flag` ( #102 )

## 0.6.1

  - Allow dynamic help content

## 0.6.0

  - Deprecated `declare` in favor of `new Script`.

Breaking changes:

  - Script.execute now calls the method asynchronously so that it can return 
    a Future for the return value.

## 0.5.0

Breaking changes:

  - Flags without a null default value now default to null instead of false 
    when neither the flag nor it's negation occur on the command-line (#86)

## 0.4.6

Features:

  - Improve color-support detection (#73)

## 0.4.5

Features:

  - Reference scripts as `foo` instead of `foo.dart` (expect `foo.bat` in cygwin) (#80)
  - Add allowTrailingOptions to Command and SubCommand (#70)

## 0.4.4

Bugfixes:

  - Fixed omission of {Rest,Positional}.allowed (#79)

## 0.4.3

Features:

  - Colorful help output (#68)
  - Add help output for positional arguments (#42)
  - Add metaVar configuration (#43)
  - Only fail completion in windows on actual usage not definition (#75)
  - Support hidden commands (#69)
  - Allow omitting arg to `allowed` callback (#67)
  - Allow latest args version (#74)

Bugfixes:

  - Fix some checked mode errors
  - Fix running scripts via pub run

## 0.4.0

Features:

  - Tab Completion! (#7)
  - Initial plugin support (see #62)
  - Improved examples to demo parsers and other metadata
  
Breaking changes:

  - Removed `CallStyle`

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
  