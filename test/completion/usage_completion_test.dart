
library usage_completion_test;

import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/completion/completion.dart';
import 'package:unscripted/src/usage.dart';
import 'package:unittest/unittest.dart';

main() {

  // Assumes no spaces within arguments, cursor at end of line.
  // That is tested in the CommandLine tests.
  CommandLine makeSimpleCommandLine(String line) {
    line = 'foo $line';
    var args = line.split(new RegExp(r'\s+'));
    var cWord = args.length - 1;
    if(args.last == '') args.removeLast();
    return new CommandLine(args, environment: {
      'COMP_LINE' : line,
      'COMP_POINT': line.length.toString(),
      'COMP_CWORD': cWord.toString()
    });
  }

  testAllowed(Usage usage, String line, expectedCompletions) {
    var completions = getUsageCompletions(usage, makeSimpleCommandLine(line));
    expect(completions, expectedCompletions);
  }

  group('getUsageCompletions', () {

    group('when usage empty', () {

      test('should complete -- to --help', () {
        testAllowed(new Usage(), '--', ['--help']);
      });

    });

    group('when completing long option', () {

      test('should suggest all long options for --', () {
        var usage = new Usage()
            ..addOption('aaa', new Option())
            ..addOption('bbb', new Option());

        testAllowed(usage, '--', unorderedEquals(['--help', '--aaa', '--bbb']));
      });

      test('should suggest long options with same prefix', () {
        var usage = new Usage()
            ..addOption('aaa', new Option())
            ..addOption('bbb', new Option());

        testAllowed(usage, '--a', ['--aaa']);
      });

    });

    test('should complete - to --', () {
      var usage = new Usage()
          ..addOption('opt', new Option(abbr: 'o'));

      var completions = getUsageCompletions(usage, makeSimpleCommandLine('-'));
      expect(completions, hasLength(2));
      expect(completions.first, '--');
      expect(completions.last, hasLength(greaterThan(2)));
      expect(completions.last, startsWith('--'));
    });


    test('should complete short option to long option', () {
      var usage = new Usage()
          ..addOption('opt', new Option(abbr: 'o'))
          ..addOption('flag', new Flag(abbr: 'f'));

      testAllowed(usage, '-o', ['--opt']);
      testAllowed(usage, '-f', ['--flag']);
    });

    group('when completing option value', () {

      test('should suggest allowed', () {
        var usage = new Usage()
            ..addOption('aaa', new Option(abbr: 'a', allowed: ['x', 'y', 'z']))
            ..addOption('bbb', new Option(abbr: 'b', allowed: {'x': '', 'y': '', 'z': ''}))
            ..addOption('ccc', new Option(abbr: 'c'))
            ..addOption('flag', new Flag(abbr: 'f'));

        testAllowed(usage, '--aaa ', ['x', 'y', 'z']);
        testAllowed(usage, '-a ', ['x', 'y', 'z']);
        testAllowed(usage, '--bbb ', ['x', 'y', 'z']);
        testAllowed(usage, '-b ', ['x', 'y', 'z']);
        testAllowed(usage, '--ccc ', []);
        testAllowed(usage, '-c ', []);
        testAllowed(usage, '-f ', []);
      });

      test('should suggest allowed result when allowed is a func', () {
        var usage = new Usage()
            ..addOption('aaa', new Option(abbr: 'a', allowed: (partial) => ['x', 'y', 'z']));

        testAllowed(usage, '--aaa ', ['x', 'y', 'z']);
        testAllowed(usage, '--aaa x', ['x']);
        testAllowed(usage, '-a ', ['x', 'y', 'z']);
        testAllowed(usage, '-a x', ['x']);
      });

    });

    group('when completing positional value', () {

      test('should suggest allowed', () {
        var usage = new Usage()
            ..addPositional(new Positional(allowed: ['aa', 'bb', 'cc']))
            ..addPositional(new Positional(allowed: {'aa': '', 'bb': '', 'cc': ''}));

        testAllowed(usage, '', ['aa', 'bb', 'cc']);
        testAllowed(usage, 'a', ['aa']);
        testAllowed(usage, 'aa b', ['bb']);
        testAllowed(usage, 'aa bb c', []);
      });

      test('should suggest allowed result when allowed is a func', () {
        var usage = new Usage()
            ..addPositional(new Positional(allowed: (partial) => ['aa', 'bb', 'cc']));

        testAllowed(usage, '', ['aa', 'bb', 'cc']);
        testAllowed(usage, 'a', ['aa']);
        testAllowed(usage, 'aa b', []);
      });

      test('should suggest allowed result when allowed is a func', () {
        var usage = new Usage()
            ..addPositional(new Positional())
            ..rest = new Rest(allowed: ['aa', 'bb', 'cc']);

        testAllowed(usage, '', []);
        testAllowed(usage, 'x ', ['aa', 'bb', 'cc']);
        testAllowed(usage, 'x aa b', ['bb']);
      });

    });

    group('when completing a command', () {

      test('should suggest available commands', () {
        var usage = new Usage()
            ..addCommand('xcommand')
            ..addCommand('ycommand');

        testAllowed(usage, '', unorderedEquals(['help', 'xcommand', 'ycommand']));
      });

      test('should suggest commands matching incomplete word', () {
        var usage = new Usage()
            ..addCommand('xcommand')
            ..addCommand('ycommand');

        testAllowed(usage, 'x', ['xcommand']);
      });

    });

  });

}
