unscripted
==========

[![Build Status](https://drone.io/github.com/seaneagan/unscripted/status.png)](https://drone.io/github.com/seaneagan/unscripted/latest)

Unscripted is a [pub package][pkg] for declarative command-line interface
programming in dart.  Command-line interfaces are defined using ordinary method
and class declarations, minimally annotated with command-line metadata.  
Reflection is used to derive the command-line interface from the declarations.  
Command-line arguments are automatically injected into the method or
class (constructor).  This removes the need for boilerplate logic to define, 
parse, validate and assign variables for command-line arguments.  Since the 
interface is defined in code, standard refactoring, testing, etc. tools can 
be used.

##Demo

[cat.dart][cat.dart] is a complete implementation of the *nix `cat` 
utility using unscripted.

##Usage

(For more detailed usage, see the [API docs][api_docs])

A simple script to output a greeting:

```dart
import 'package:unscripted/unscripted.dart';

main(arguments) => declare(greet).execute(arguments);

@Command(help: 'Outputs a greeting')
@ArgExample('--salutation Welcome --exclaim Bob', help: 'enthusiastic')
greet(
    @Rest(help: "Name(s) to greet")
    List<String> who, // A rest parameter, must be last positional.
    {String salutation : 'Hello', // An option, use `@Option(...)` for metadata.
     bool exclaim : false}) { // A flag, use `@Flag(...)` for metadata.

  print('$salutation ${who.join(' ')}${exclaim ? '!' : ''}');

}
```

(Compare to a [traditiional version][old_greet] of this script.)

We can call this script as follows:

```shell
$ dart greet.dart Bob
Hello Bob
$ dart greet.dart --salutation Welcome --exclaim Bob
Welcome Bob!
```

###Automatic --help

Unscripted automatically defines and handles a --help/-h option,
allowing for:

```shell
$ dart greet.dart --help
Outputs a greeting

Usage:

dart greet.dart [options] WHO...

Options:

-h, --help            Print this usage information.
    --salutation      (defaults to "Hello")
    --[no-]exclaim

Examples:

dart greet.dart --salutation Welcome --exclaim Bob # enthusiastic
```

###Sub-Commands

Sub-commands are also supported.  In this case the script is defined as a
class, whose instance methods can be annotated as sub-commands.  Assume we have
the following 'server.dart':

```dart
import 'package:unscripted/unscripted.dart';

main(arguments) => declare(Server).execute(arguments);

class Server {

  final String configPath;

  @Command(help: 'Manages a server')
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

A 'help' sub-command is also added, which can be used as a synonym for '--help',
which outputs all the basic help info *plus* a list of available commands:

```shell
$ dart server.dart help
Available commands:

  start
  help
  stop

Use "dart server.dart help [command]" for more information about a command.
```

and as indicated there, sub-command help is also available:

```shell
$ dart server.dart help stop
Stop the server

Usage:

dart server.dart stop [options]

Options:

-h, --help    Print this usage information.
```

[pkg]: http://pub.dartlang.org/packages/unscripted
[cat.dart]: https://github.com/seaneagan/unscripted/blob/master/example/cat.dart
[api_docs]: https://seaneagan.github.com/unscripted/unscripted.html
[declare]: https://seaneagan.github.com/unscripted/unscripted.html#declare
[examples]: https://github.com/seaneagan/unscripted/tree/master/example
[old_greet]: https://github.com/seaneagan/unscripted/tree/master/example/old_greet.dart