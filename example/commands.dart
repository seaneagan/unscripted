#!/usr/bin/env dart

import 'package:ink/ink.dart';

/// A simple comand line script with sub-commands.
main(arguments) => ink(Commands).execute(arguments);

@Command(help: 'Does command-ish stuff')
class Commands {

  @SubCommand()
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
