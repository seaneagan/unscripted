
library completion_command_test;

import 'dart:async';

import 'package:unscripted/unscripted.dart';
import 'package:unittest/unittest.dart';

import 'util.dart';

main() {

  group('completion command', () {

    test('installation', () {
      var args = ['completion'];
      declare(f)
      .execute(args, isWindows: false);
    });

    test('completions output is correct', () {

      var output = captureOutput(() {
        var args = ['completion', 'foo_command', '--'];
        declare(f)
            .execute(args, environment: makeEnv(args), isWindows: false);
      });

      expect(output, '''
--help
--foo
--bar
''');

    });

    test('completions output is empty', () {

      var output = captureOutput(() {
        var args = ['completion', 'foo_command', '--blah'];
        declare(f)
            .execute(args, environment: makeEnv(args), isWindows: false);
      });

      expect(output, '');
    });

  });

}

@Command(completion: true, callStyle: CallStyle.SHELL)
f({int foo, String bar}) {}

String captureOutput(f()) {

  var buffer = new StringBuffer();

  runZoned(f, zoneSpecification:
    new ZoneSpecification(print: (_, __, ___, line) {
      buffer.writeln(line);
    }
  ));

  return buffer.toString();
}
