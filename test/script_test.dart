
library script_test;

import 'dart:io';

import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/script_impl.dart';
import 'package:unittest/unittest.dart';

List _lastSeenRest;

main() {

  group('Script', () {

    bool _happened;

    setUp(() {
      _happened = false;
      _lastSeenRest = null;
    });

    tearDown(() {
      // UsageExceptions set exit code to 2.
      exitCode = 0;
    });

    expectUsageError() {
      expect(_happened, isFalse);
      // TODO: Uncomment once http://dartbug.com/16217 is fixed.
      // expect(exitCode, 2);
    }

    group('FunctionScript', () {

      test('no args', () {
        new FunctionScript(() {_happened = true;}).execute([]);
        expect(_happened, true);
      });

      test('flag from bool', () {
        var flagValue;
        new FunctionScript(({bool flag}) {
          flagValue = flag;
        }).execute(['--flag']);
        expect(flagValue, true);
      });

      test('option from String', () {
        var optionValue;
        new FunctionScript(({String option}) {
          optionValue = option;
        }).execute(['--option', 'value']);
        expect(optionValue, 'value');
      });

      test('flag from Flag', () {
        var flagValue;
        new FunctionScript(({@Flag() flag}) {
          flagValue = flag;
        }).execute(['--flag']);
        expect(flagValue, true);
      });

      test('option from Option', () {
        var optionValue;
        new FunctionScript(({@Option() option}) {
          optionValue = option;
        }).execute(['--option', 'value']);
        expect(optionValue, 'value');
      });

      test('positionals', () {
        var firstValue;
        var secondValue;
        new FunctionScript((String first, String second, {bool flag}) {
          firstValue = first;
          secondValue = second;
        }).execute(['--flag', 'first', 'second']);
        expect(firstValue, 'first');
        expect(secondValue, 'second');
      });

      test('too many positionals', () {
        new FunctionScript((String first) {
          _happened = true;
        }).execute(['first', 'extra']);
        expectUsageError();
      });

      test('not enough positionals', () {
        new FunctionScript((String first) {
          _happened = true;
        }).execute([]);
        expectUsageError();
      });

      test('rest from Rest', () {
        var firstValue;
        new FunctionScript((String first, @Rest() rest) {
          firstValue = first;
          _lastSeenRest = rest;
        }).execute(['first', 'second', 'third', 'fourth']);
        expect(firstValue, 'first');
        expect(_lastSeenRest, ['second', 'third', 'fourth']);
      });

      test('not enough rest', () {
        new FunctionScript((String first, @Rest(required: true) rest) {
          _happened = true;
        }).execute(['first']);
        expectUsageError();
      });

      test('dashed arg', () {
        var flagValue;
        new FunctionScript(({bool dashedFlag}) {
          flagValue = dashedFlag;
        }).execute(['--dashed-flag']);
        expect(flagValue, true);
      });

      test('--help prevents command from executing', () {
        new FunctionScript(() {
          _happened = true;
        }).execute(['--help']);
        expect(_happened, false);
      });

      SubCommandScriptTest withSubCommands({bool flag1}) {
        return new SubCommandScriptTest(flag1: flag1);
      }

      test('with sub-commands', () {
        new FunctionScript(withSubCommands).execute(['--flag1', 'recursive2', '--flag2']);
      });

    });

    group('parser', () {
      test('for Option - valid input', () {
        var optionValue;
        new FunctionScript(({@Option(parser: int.parse) int option}) {
          optionValue = option;
        }).execute(['--option', '123']);
        expect(optionValue, 123);
      });

      test('for Option - from type annotation', () {
        var optionValue;
        new FunctionScript(({int option}) {
          optionValue = option;
        }).execute(['--option', '123']);
        expect(optionValue, 123);
      });

      test('for Option - invalid input throws', () {
        new FunctionScript(({@Option(parser: int.parse) int option}) {
          _happened = true;
        }).execute(['--option', 'abc']);
        expectUsageError();
      });

      test('for Option - with allowMultiple', () {
        var optionValues;
        new FunctionScript(({@Option(parser: int.parse, allowMultiple: true) List<int> option}) {
          optionValues = option;
        }).execute(['--option', '1', '--option', '2']);
        expect(optionValues, [1, 2]);
      });

      test('for Option - from List type annotation', () {
        var optionValues;
        new FunctionScript(({List<int> option}) {
          optionValues = option;
        }).execute(['--option', '1', '--option', '2']);
        expect(optionValues, [1, 2]);
      });

      test('for Positional - valid input', () {
        var positionalValue;
        var restValue;
        new FunctionScript((
            @Positional(parser: int.parse) int first,
            @Rest(parser: int.parse) List<int> rest) {
          positionalValue = first;
          restValue = rest;
        }).execute(['123', '4', '5', '6']);
        expect(positionalValue, 123);
        expect(restValue, [4, 5, 6]);
      });

      test('for Positional - from type annotation', () {
        var positionalValue;
        var restValue;
        new FunctionScript((
            int first,
            List<int> rest) {
          positionalValue = first;
          restValue = rest;
        }).execute(['123', '4', '5', '6']);
        expect(positionalValue, 123);
        expect(restValue, [4, 5, 6]);
      });

      test('not called on default values', () {
        var optionValue;
        new FunctionScript(({int option : 1}) {
          optionValue = option;
        }).execute([]);
        expect(optionValue, 1);
      });

      test('for Positional - invalid input throws', () {
        new FunctionScript((@Positional(parser: int.parse) int first) {
          _happened = true;
        }).execute(['abc']);
        expectUsageError();
      });

    });

    group('ClassScript', () {

      Script unit;

      setUp(() {
        unit = new ClassScript(CommandScriptTest);
        CommandScriptTest._commandHappened = false;
        CommandScriptTest._dashedCommandHappened = false;
      });

      test('default values', () {
        unit.execute(['command']);
        expect(CommandScriptTest._commandHappened, isTrue);
        expect(CommandScriptTest._lastSeen.flag, false);
        expect(CommandScriptTest._lastSeen.option, 'default');
      });

      test('args resolved', () {
        unit.execute(['--flag', '--option', 'value', 'command']);
        expect(CommandScriptTest._commandHappened, isTrue);
        expect(CommandScriptTest._lastSeen.flag, true);
        expect(CommandScriptTest._lastSeen.option, 'value');
      });

      test('rest', () {
        unit.execute(['command', '1', '2']);
        expect(CommandScriptTest._commandHappened, isTrue);
        expect(_lastSeenRest, ['1', '2']);
      });

      test('bad base args', () {
        unit.execute(['--bogusflag', '--bogusoption', 'value', 'command']);
        expect(CommandScriptTest._commandHappened, isFalse);
      });

      test('no command', () {
        unit.execute([]);
        expect(CommandScriptTest._commandHappened, isFalse);
      });

      test('dashed command', () {
        unit.execute(['dashed-command']);
        expect(CommandScriptTest._dashedCommandHappened, isTrue);
      });

      test('recursive sub-commands', () {
        unit.execute(['recursive1', '--flag1', 'recursive2', '--flag2']);
      });

    });
  });
}

class CommandScriptTest {
  final bool flag;
  final String option;

  static CommandScriptTest _lastSeen;
  static bool _commandHappened;
  static bool _dashedCommandHappened;

  @Command(help: 'Test command with sub-commands')
  CommandScriptTest({this.flag: false, this.option: 'default'});

  @SubCommand()
  command(@Rest() rest, {bool commandFlag}) {
    _lastSeen = this;
    _lastSeenRest = rest;
    _commandHappened = true;
  }

  @SubCommand()
  dashedCommand() {
    _lastSeen = this;
    _dashedCommandHappened = true;
  }

  @SubCommand(help: 'Test sub-command with sub-commands')
  SubCommandScriptTest recursive1({bool flag1}) => new SubCommandScriptTest(flag1: flag1);
}

class SubCommandScriptTest {

  final bool flag1;

  SubCommandScriptTest({this.flag1});

  @SubCommand()
  recursive2({bool flag2}) {
    print('flag1: $flag1');
    print('flag2: $flag2');
  }

}

@Command() final int
  A = 1,
  B = 2,
  C = 3;
