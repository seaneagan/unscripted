
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

  group('getUsageCompletions', () {

    group('when usage empty', () {

      test('should complete -- to --help', () {
        var commandLine = makeSimpleCommandLine('--');
        var completions = getUsageCompletions(new Usage(), commandLine);
        expect(completions, ['--help']);
      });

    });

    group('when completing long option', () {

      test('should suggest all long options for --', () {
        var commandLine = makeSimpleCommandLine('--');
        var usage = new Usage()
            ..addOption('aaa', new Option())
            ..addOption('bbb', new Option());

        var completions = getUsageCompletions(usage, commandLine);
        expect(completions, ['--help', '--aaa', '--bbb']);
      });

      test('should suggest long options with same prefix', () {
        var commandLine = makeSimpleCommandLine('--a');
        var usage = new Usage()
            ..addOption('aaa', new Option())
            ..addOption('bbb', new Option());

        var completions = getUsageCompletions(usage, commandLine);
        expect(completions, ['--aaa']);
      });

    });

    test('should complete - to --', () {
      var usage = new Usage()
          ..addOption('opt', new Option(abbr: 'o'));

      var completions = getUsageCompletions(usage, makeSimpleCommandLine('-'));
      expect(completions, ['--']);
    });


    test('should complete short option to long option', () {
      var usage = new Usage()
          ..addOption('opt', new Option(abbr: 'o'))
          ..addOption('flag', new Flag(abbr: 'f'));

      expect(getUsageCompletions(usage, makeSimpleCommandLine('-o')), ['--opt']);
      expect(getUsageCompletions(usage, makeSimpleCommandLine('-f')), ['--flag']);
    });

    group('when completing option value', () {

      test('should suggest allowed', () {
        var usage = new Usage()
            ..addOption('aaa', new Option(abbr: 'a', allowed: ['x', 'y', 'z']))
            ..addOption('bbb', new Option(abbr: 'b', allowed: {'x': '', 'y': '', 'z': ''}))
            ..addOption('ccc', new Option(abbr: 'c'))
            ..addOption('flag', new Flag(abbr: 'f'));

        testAllowed(String line, Iterable<String> expectedCompletions) {
          var completions = getUsageCompletions(usage, makeSimpleCommandLine(line));
          expect(completions, expectedCompletions);
        }
        testAllowed('--aaa ', ['x', 'y', 'z']);
        testAllowed('-a ', ['x', 'y', 'z']);
        testAllowed('--bbb ', ['x', 'y', 'z']);
        testAllowed('-b ', ['x', 'y', 'z']);
        testAllowed('--ccc ', []);
        testAllowed('-c ', []);
        testAllowed('-f ', []);
      });

      test('should suggest allowed result when allowed is a func', () {
        var usage = new Usage()
            ..addOption('aaa', new Option(abbr: 'a', allowed: (partial) => ['x', 'y', 'z']));

        testAllowed(String line, Iterable<String> expectedCompletions) {
          var completions = getUsageCompletions(usage, makeSimpleCommandLine(line));
          expect(completions, expectedCompletions);
        }
        testAllowed('--aaa ', ['x', 'y', 'z']);
        testAllowed('--aaa x', ['x']);
        testAllowed('-a ', ['x', 'y', 'z']);
        testAllowed('-a x', ['x']);
      });

    });

    group('when completing a command', () {

      test('should suggest available commands', () {
        var commandLine = makeSimpleCommandLine(' ');
        var usage = new Usage()
            ..addCommand('xcommand')
            ..addCommand('ycommand');

        var completions = getUsageCompletions(usage, commandLine);
        expect(completions, unorderedEquals(['help', 'xcommand', 'ycommand']));
      });

      test('should suggest commands matching incomplete word', () {
        var commandLine = makeSimpleCommandLine(' x');
        var usage = new Usage()
            ..addCommand('xcommand')
            ..addCommand('ycommand');

        var completions = getUsageCompletions(usage, commandLine);
        expect(completions, ['xcommand']);
      });

    });

  });

}
