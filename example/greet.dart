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
