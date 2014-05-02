
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
    return new CommandLine(args, environment: {
      'COMP_LINE' : line,
      'COMP_POINT': line.length.toString(),
      'COMP_CWORD': (args.length - 1).toString()
    });
  }

  group('getUsageCompletions', () {

    group('when usage empty', () {

      test('-- suggests --help', () {
        var commandLine = makeSimpleCommandLine('--');
        var completions = getUsageCompletions(new Usage(), commandLine);
        expect(completions, ['--help']);
      });

      test('- suggests -h', () {
        var commandLine = makeSimpleCommandLine('-');
        var completions = getUsageCompletions(new Usage(), commandLine);
        expect(completions, ['-h']);
      });

    });

    group('when completing long option', () {

      test('suggests all long options', () {
        var commandLine = makeSimpleCommandLine('--');
        var usage = new Usage()
            ..addOption('aaa', new Option())
            ..addOption('bbb', new Option());

        var completions = getUsageCompletions(usage, commandLine);
        expect(completions, ['--help', '--aaa', '--bbb']);
      });

      test('suggests long options with same prefix', () {
        var commandLine = makeSimpleCommandLine('--a');
        var usage = new Usage()
            ..addOption('aaa', new Option())
            ..addOption('bbb', new Option());

        var completions = getUsageCompletions(usage, commandLine);
        expect(completions, ['--aaa']);
      });

    });

    group('when completing short option', () {

      test('suggests all short options', () {
        var commandLine = makeSimpleCommandLine('-');
        var usage = new Usage()
            ..addOption('aaa', new Option(abbr: 'a'))
            ..addOption('bbb', new Option(abbr: 'b'));

        var completions = getUsageCompletions(usage, commandLine);
        expect(completions, ['-h', '-a', '-b']);
      });

      test('suggests short flags not already specified', () {
        var commandLine = makeSimpleCommandLine('-x');
        var usage = new Usage()
            ..addOption('opt', new Option(abbr: 'o'))
            ..addOption('xflag', new Flag(abbr: 'x'))
            ..addOption('yflag', new Flag(abbr: 'y'));

        var completions = getUsageCompletions(usage, commandLine);
        // TODO: Do we really want 'h' (help) here?  Makes sense for -vh
        // (verbose help) for example.
        expect(completions, ['-xh', '-xy']);
      });

    });

    group('when completing option value', () {

      test('suggests allowed when specified', () {
        var commandLine = makeSimpleCommandLine('--aaa ');
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
        testAllowed('--flag ', []);
        testAllowed('-f ', []);
      });

    });

    group('when completing a command', () {

      test('suggests available commands', () {
        var commandLine = makeSimpleCommandLine(' ');
        var usage = new Usage()
            ..addCommand('xcommand')
            ..addCommand('ycommand');

        var completions = getUsageCompletions(usage, commandLine);
        expect(completions, unorderedEquals(['help', 'xcommand', 'ycommand']));
      });

      test('suggests commands matching incomplete word', () {
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
