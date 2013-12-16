unscripted
==========

[![Build Status](https://drone.io/github.com/seaneagan/unscripted/status.png)](https://drone.io/github.com/seaneagan/unscripted/latest)

Unscripted is a [pub package][pkg] for dart which enables the design of command
line interfaces using the same programming constructs used to design regular
Dart APIs, such as methods, parameters, classes, and constructors, merely
annotating these as necessary with command line specific metadata.

Command line parameters, just like dart method parameters, come in two varieties,
named and positional.  This makes for a nice mapping between command line scripts
and dart methods.  Unscripted uses reflection to transform between the two.
It also applies the concept of dependency injection to inject command line
arguments into dart methods.  This removes the need for boilerplate logic
around command line arguments to define, parse, validate and assign them to
local variables.  This allows making command line interface changes solely
via dart refactoring tools or even simple one-liners, and makes for less untested
code.

The quickest way to get started is to copy one of the examples below
(also available [here][examples]) and edit as necessary.

More detailed usage is available in the [API docs][api_docs].

##Usage

Let's say we want to write a simple script to output a greeting to one or more
people with a few options sprinkled in to customize the output to make it
interesting.  The status quo dart script for this is too long to embed here,
but might look something like [this][old_greet].  With unscripted, we can get
rid a lot of boilerplate, retaining only the `greet` method, annotating it
with a bit of command line metadata:

```dart
import 'package:unscripted/unscripted.dart';

main(arguments) => improvise(greet).execute(arguments);

// Optional command-line metadata:
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

We can call this script as follows:

```shell
dart greet.dart Bob
Hello Bob
dart greet.dart --salutation Welcome --exclaim Bob
Welcome Bob!
```

###Automatic --help

Unscripted also automatically defines and handles a --help/-h option,
allowing for:

```shell
$ dart greet.dart --help
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

###Sub-Commands

Sub-commands are also supported.  In this case the script is defined as a
class, whose instance methods can be annotated as sub-commands.  Assume we have
the following 'server.dart':

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
[api_docs]: https://seaneagan.github.com/unscripted/unscripted.html
[improvise]: https://seaneagan.github.com/unscripted/unscripted.html#improvise
[examples]: https://github.com/seaneagan/unscripted/tree/master/example
[old_greet]: https://github.com/seaneagan/unscripted/tree/master/example/old_greet.dart
