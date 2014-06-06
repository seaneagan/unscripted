#!/usr/bin/env dart

import 'package:unscripted/unscripted.dart';

main(arguments) => declare(greet).execute(arguments, isWindows: false);

// Optional command-line metadata:
@Command(help: 'Outputs a greeting', plugins: const [const Completion()], callStyle: CallStyle.SHEBANG)
@ArgExample('--salutation Welcome --exclaim Bob', help: 'enthusiastic')
greet(
    @Rest(help: "Name(s) to greet") List<String> who,
    {String salutation : 'Hello', // An option, use `@Option(...)` for metadata.
     bool exclaim : false}) { // A flag, use `@Flag(...)` for metadata.

  print('$salutation${who == null ? '' : ' ${who.join(' ')}'}${exclaim ? '!' : ''}');

}
