unscripted
==========

[![Build Status](https://drone.io/github.com/seaneagan/unscripted/status.png)](https://drone.io/github.com/seaneagan/unscripted/latest)

Unscripted is a pub package for dart which enables one to design a command line
interface using the same programming constructs they would use to design
a regular Dart API, such as methods, parameters, classes, and constructors,
merely annotating these as necessary with command line specific metadata.

Command line parameters, just like dart method parameters, come in two varieties,
named and positional.  This makes for a nice mapping between command line scripts
and dart methods.  Unscripted uses reflection to transform between the two.
It also applies the concept of dependency injection to inject command line
arguments into dart methods.  This removes the need for boilerplate logic
around command line arguments to define, parse, validate and assign them to
local variables.  This allows making command line interface changes solely
via dart refactoring tools or even simple edits, and makes for less untested
code.

##Usage

A basic script (without sub-commands) can be defined using a closure.  Assume we
have the following 'greet.dart' script:

```dart
import 'package:unscripted/unscripted.dart';

main(arguments) => improvise(greet).execute(arguments);

@Command(help: 'Outputs a greeting')
@ArgExample('--salutation Welcome --exclaim Bob', help: 'enthusiastic')
greet(
    @Rest(help: "One or more names to greet, e.g. 'Jack' or 'Jack Jill'")
    List<String> who, // A "rest parameter.
    {String salutation : 'Hello', // An option.
     bool exclaim : false}) { // A flag.

  print('$salutation ${who.join(' ')}${exclaim ? '!' : ''}');

}
```

We can call this script as follows:

```shell
dart greet.dart Bob
Hello Bob
dart greet.dart --salutation Welcome --exclaim Bob
Welcome Bob!
```

Unscripted also automatically defines and handles a '--help'/'-h' option,
allowing for:

```shell
dart greet.dart --help
Outputs a greeting

Usage:

dart greet.dart [options] One or more names to greet, e.g. 'Jack' or 'Jack Jill'

Options:

-h, --help            Print this usage information.
    --salutation      (defaults to "Hello")
    --[no-]exclaim

Examples:

dart greet.dart --salutation Welcome --exclaim Bob # enthusiastic
```

###Sub-Command support

Sub-commands are also supported.  In this case the script is defined as a
class, whose instance methods can be annotated as sub-commands:

```dart
import 'package:unscripted/unscripted.dart';

main(arguments) => improvise(Server).execute(arguments);

@Command(help: 'Manages a server')
class Server {

  final String configPath;

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
dart server.dart start --config-path my-config.xml --clean
Starting the server.
Config path: my-config.xml
```

A 'help' sub-command is also added, which can be used as a synonym for '--help',
in which case it outputs a list of available commands:

```shell
dart server.dart help
Usage:

dart server.dart command

Options:

-h, --help           Print this usage information.
    --config-path    (defaults to "config.xml")

Available commands:

  start
  help
  stop

Use "dart server.dart help [command]" for more information about a command.
```

or for a specific sub-command

```shell
dart server.dart help stop
Stop the server

Usage:

dart server.dart stop [options]

Options:

-h, --help    Print this usage information.
```

For more detailed usage, check out the [API docs][api_docs].

[api_docs]: https://seaneagan.github.io/unscripted/unscripted.html
[improvise]: https://seaneagan.github.io/unscripted/unscripted.html#improvise
