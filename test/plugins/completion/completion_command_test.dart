
library completion_command_test;

import 'dart:async';

import 'package:unscripted/unscripted.dart';
import 'package:test/test.dart';

import 'util.dart';

main() {

  group('completion command', () {

    test('installation', () {
      var args = ['completion'];
      new Script(f).execute(args, isWindows: false);
    });

    test('completions output is correct', () {

      var output = captureOutput(() {
        var args = ['completion', 'foo_command', '--'];
        return new Script(f)
            .execute(args, environment: makeEnv(args), isWindows: false);
      });

      expect(output, completion('''
--help
--foo
--bar
'''));

    });

    test('completions output is empty', () {

      var output = captureOutput(() {
        var args = ['completion', 'foo_command', '--blah'];
        return new Script(f)
            .execute(args, environment: makeEnv(args), isWindows: false);
      });

      expect(output, completion(''));
    });

  }, skip: '`fails with `pub run test` for unknown reason');

}

@Command(plugins: const [const Completion()])
f({int foo, String bar}) {}

Future<String> captureOutput(f()) {
  var buffer = new StringBuffer();
  return runZoned(() => new Future(f), zoneSpecification:
    new ZoneSpecification(print: (_, __, ___, line) {
      buffer.writeln(line);
    }
  )).then((_) => buffer.toString());
}
