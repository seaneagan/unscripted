#!/usr/bin/env dart

import 'package:unscripted/unscripted.dart';

main(arguments) => declare(greet).execute(arguments);

// All metadata annotations are optional.
@Command(help: 'Outputs a greeting', plugins: const [const Completion()])
@ArgExample('--salutation Hi --enthusiasm 3 Bob', help: 'enthusiastic')
greet(
    @Rest(help: 'Name(s) to greet')
    List<String> who, {
      @Option(help: '')
      String salutation : 'Hello',
      int enthusiasm : 0,
      @Flag(abbr: 'l')
      bool lineMode : false
    }) {

  print(salutation +
        who.map((w) => (lineMode ? '\n  ' : ' ') + w).join(',') +
        '!' * enthusiasm);
}
