#!/usr/bin/env dart

import 'package:unscripted/unscripted.dart';

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
