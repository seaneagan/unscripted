unscripted
==========

[![Build Status](https://drone.io/github.com/seaneagan/unscripted/status.png)](https://drone.io/github.com/seaneagan/unscripted/latest) | [API docs][api_docs]

*Define command-line interfaces using ordinary dart methods and classes.*

##Installation

Add the [unscripted package][pkg] to your pubspec.yaml dependencies:

`unscripted: >=0.4.0 <0.5.0`

##Usage

The following [greet.dart][greet.dart] script outputs a configurable greeting:

```dart
#!/usr/bin/env dart

import 'package:unscripted/unscripted.dart';

main(arguments) => declare(greet).execute(arguments);

// All metadata annotations are optional.
@Command(help: 'Print a configurable greeting', plugins: const [const Completion()])
@ArgExample('--salutation Hi --enthusiasm 3 Bob', help: 'enthusiastic')
greet(
    @Rest(help: 'Name(s) to greet.')
    List<String> who, {
      @Option(help: 'Alternate word to greet with e.g. "Hi".')
      String salutation : 'Hello',
      @Option(help: 'How many !\'s to append.')
      int enthusiasm : 0,
      @Flag(abbr: 'l', help: 'Put names on separate lines.')
      bool lineMode : false
    }) {

  print(salutation +
        who.map((w) => (lineMode ? '\n  ' : ' ') + w).join(',') +
        '!' * enthusiasm);
}
```

We can call this script as follows:

```shell
$ greet Bob
Hello Bob
$ greet --salutation Hi --enthusiasm 3 -l Alice Bob
Hi
  Alice,
  Bob!!!
```

##Automatic --help

A `--help`/`-h` flag is automatically defined:

```shell
$ greet.dart --help
Print a configurable greeting

Usage:

  greet.dart [options] [WHO]...

Options:

      --salutation         Alternate word to greet with e.g. "Hi".
      --enthusiasm         How many !'s to append.
  -l, --line-mode          Put names on separate lines.
      --completion         Tab completion for this command.

            [install]      Install completion script to .bashrc/.zshrc.
            [print]        Print completion script to stdout.
            [uninstall]    Uninstall completion script from .bashrc/.zshrc.

  -h, --help               Print this usage information.

Examples:

  greet.dart --salutation Hi --enthusiasm 3 Bob # enthusiastic

```

##Sub-Commands

Sub-commands are represented as `SubCommand`-annotated instance methods of 
classes, as seen in the following [server.dart][server.dart]:

```dart
#!/usr/bin/env dart

import 'dart:io';

import 'package:unscripted/unscripted.dart';
import 'package:path/path.dart' as path;

main(arguments) => declare(Server).execute(arguments);

class Server {

  final String configPath;

  @Command(
      help: 'Manages a server',
      plugins: const [const Completion()])
  Server({this.configPath: 'config.xml'});

  @SubCommand(help: 'Start the server')
  start({bool clean}) {
    print('''
Starting the server.
Config path: $configPath''');
  }

  @SubCommand(help: 'Stop the server')
  stop() {
    print('Stopping the server.');
  }

}
```

We can call this script as follows:

```shell
$ dart server.dart start --config-path my-config.xml --clean
Starting the server.
Config path: my-config.xml
```

Help is also available for sub-commands:

```shell
$ dart server.dart help
Available commands:

  start
  help
  stop

Use "dart server.dart help [command]" for more information about a command.

$ dart server.dart help stop
Stop the server

Usage:

dart server.dart stop [options]

Options:

-h, --help    Print this usage information.
```

##Parsers

Any value-taking argument (option, positional, rest) can have a "parser"
responsible for validating and transforming the string passed on the command 
line.  You can give an argument a parser simply by giving it a type (such as 
`int` or `DateTime`) which has a static `parse` method, or by specifying the 
`parser` named argument of the argument's metadata (`Option`, `Positional`, or 
`Rest`).

##Plugins

Plugins allow you to mixin reusable chunks of cli-specific functionality 
(options/flags/commands) on top of your base interface.

To add a plugin to your script, just add an instance of the associated plugin
class to the `plugins` named argument of your `@Command` annotation.  The 
following plugins are available:

###Tab Completion

Add bash/zsh [tab completion][tab completion] to your script:

```dart
#!/usr/bin/env dart
// ...
@Command(plugins: const [const Completion()])
```

(Once [pub supports cli's](http://dartbug.com/7874), the "shebang" line will no 
longer be required.)

If your script already has sub-commands, this will add a `completion` 
sub-command, otherwise it adds a `--completion` option.  These can then be used 
as follows:

```shell
# Try the tab-completion without permanently installing.
. <(greet.dart --completion print)
. <(server.dart completion print)

# Install the completion script to .bashrc/.zshrc depending on current shell.
# No-op if already installed.
greet.dart --completion install
server.dart completion install

# Uninstall a previously installed completion script.
# No-op if not installed.
greet.dart --completion uninstall
server.dart completion uninstall
```

Once installed, the user will be able to tab-complete all aspects of your cli,
for example:

**Option/Flag names:** Say your script is a dart method with a 
`longOptionName` named parameter.  This becomes `--long-option-name` in your 
cli, and once completion is installed, the user can type `--l[TAB]` and it will 
be completed to `--long-option-name`.  It will also expand short options to their 
long equivalents, e.g. `-vh[TAB]` becomes `--verbose --help`.

**Commands:** If your script is a dart class having a `@SubCommand() 
longCommandName` method, that becomes a `long-command-name` sub-command in your 
cli, and the user can type `l[TAB]` and it will be completed to 
`long-command-name`.

**Option/Positional/Rest values:** The `allowed` named parameter of `Option` and 
`Positional` specifies the allowed values, and thus completions, for those 
parameters.  For example if you have 
`@Option(allowed: const ['red', 'yellow', 'green']) textColor`, and the user 
types `--text-color g[TAB]` this will become `--text-color green`.  In addition
to `Iterable<String>`, allowed can also be a function of the form 
`Iterable<String> complete(String text)`, or it can even return a Future 
`Future<Iterable<String>> complete(String text)`.  For example if the 
option/positional represents a file name, you could emulate the builtin shell
file name completion by returning a list of filenames in the current directory.

Tab completion is supported in [cygwin][cygwin], with one minor bug (#64).

###Other Plugins

There are several other plugins planned, and also the ability to write your own
is planned, see #62.

##Demo

[cat.dart][cat.dart] is a complete implementation of the *nix `cat` 
utility using unscripted.

[pkg]: http://pub.dartlang.org/packages/unscripted
[cat.dart]: https://github.com/seaneagan/unscripted/blob/master/example/cat.dart
[api_docs]: https://seaneagan.github.com/unscripted
[declare]: https://seaneagan.github.com/unscripted/unscripted.html#declare
[examples]: https://github.com/seaneagan/unscripted/tree/master/example
[greet.dart]: https://github.com/seaneagan/unscripted/tree/master/example/greet.dart
[server.dart]: https://github.com/seaneagan/unscripted/tree/master/example/server.dart
[old_greet]: https://github.com/seaneagan/unscripted/tree/master/example/old_greet.dart
[tab completion]: http://en.wikipedia.org/wiki/Command-line_completion
[cygwin]: http://en.wikipedia.org/wiki/Cygwin
