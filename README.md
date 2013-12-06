unscripted
==========

Unscripted is a pub package for dart which enables one to design command line
interfaces in terms of normal programming constructs such as classes,
constructors, closures, method parameters, and annotations.

It applies the concept of dependency injection to command line arguments,
which avoids the need for boilerplate assignment to local variables or method
parameters.  This allows for an [improvosational][improvise] development style,
since changes to the command line interface generally only need to be made in a
single place.

##Examples

###Basic

```dart
#!/usr/bin/env dart

import 'package:unscripted/unscripted.dart';

main(arguments) => improvise(greet).execute(arguments);

@Command(help: 'Outputs a greeting')
@ArgExample('--exclaim --salutation Howdy Mr. John Doe', help: 'enthusiastic')
greet(String title, @Rest(min: 1, help: '<names>') who, {String salutation : 'Hello', bool exclaim : false}) {
  print('$salutation $title ${who.join(' ')}${exclaim ? '!' : ''}');
}
```

###With Sub-Commands

```dart
#!/usr/bin/env dart

import 'package:unscripted/unscripted.dart';

/// A simple comand line script with sub-commands.
main(arguments) => improvise(Commands).execute(arguments);

@Command(help: 'Does command-ish stuff')
class Commands {

  @SubCommand(help: 'Does foo')
  @ArgExample('--foo-flag')
  foo({bool fooFlag}) {
    print('foo');
    print('fooFlag: $fooFlag');
  }

  @SubCommand()
  bar() {
    print('bar');
  }

  @SubCommand()
  baz(@Rest(help: '<items>') items) {
    print(items.join(', '));
    print('baz');
  }
}
```

It also supports script which nee

[improvise]: https://seaneagan.github.io/unscripted/docs#unscripted@id_improvise