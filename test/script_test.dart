
library script_test;

import 'dart:async';
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
      expect(exitCode, 2);
    }

    group('FunctionScript', () {

      test('no args', () {
        return new FunctionScript(() {_happened = true;}).execute([]).then((_) {
          expect(_happened, true);
        });
      });

      test('forwards error', () {
        var error;
        return new FunctionScript(() { throw 'e';}).execute([]).catchError((e) {
          error = e;
        }).whenComplete(() {
          expect(error, 'e');
        });
      });

      test('forwards result', () {
        return new FunctionScript(() => 0).execute([])
            .then((result) => expect(result, 0));
      });

      test('forwards future result', () {
        return new FunctionScript(() => new Future.value(0)).execute([])
            .then((result) => expect(result, 0));
      });

      test('flag from bool', () {
        var flagValue;
        return new FunctionScript(({bool flag}) {
          flagValue = flag;
        }).execute(['--flag']).then((_) {
          expect(flagValue, true);
        });
      });

      test('option from String', () {
        var optionValue;
        return new FunctionScript(({String option}) {
          optionValue = option;
        }).execute(['--option', 'value']).then((_) {
          expect(optionValue, 'value');
        });
      });

      test('flag from Flag', () {
        var flagValue;
        return new FunctionScript(({@Flag() flag}) {
          flagValue = flag;
        }).execute(['--flag']).then((_) {
          expect(flagValue, true);
        });
      });

      test('flag defaults to null by default', () {
        var flagValue;
        return new FunctionScript(({@Flag() flag}) {
          flagValue = flag;
        }).execute([]).then((_) {
          expect(flagValue, isNull);
        });
      });

      test('option from Option', () {
        var optionValue;
        return new FunctionScript(({@Option() option}) {
          optionValue = option;
        }).execute(['--option', 'value']).then((_) {
          expect(optionValue, 'value');
        });
      });

      test('positionals', () {
        var firstValue;
        var secondValue;
        return new FunctionScript((String first, String second, {bool flag}) {
          firstValue = first;
          secondValue = second;
        }).execute(['--flag', 'first', 'second']).then((_) {
          expect(firstValue, 'first');
          expect(secondValue, 'second');
        });
      });

      test('too many positionals', () {
        return new FunctionScript((String first) {
          _happened = true;
        }).execute(['first', 'extra']).then((_) {
          expectUsageError();
        });
      });

      test('not enough positionals', () {
        return new FunctionScript((String first) {
          _happened = true;
        }).execute([]).then((_) {
          expectUsageError();
        });
      });

      test('rest from Rest', () {
        var firstValue;
        return new FunctionScript((String first, @Rest() rest) {
          firstValue = first;
          _lastSeenRest = rest;
        }).execute(['first', 'second', 'third', 'fourth']).then((_) {
          expect(firstValue, 'first');
          expect(_lastSeenRest, ['second', 'third', 'fourth']);
        });
      });

      test('not enough rest', () {
        return new FunctionScript((String first, @Rest(required: true) rest) {
          _happened = true;
        }).execute(['first']).then((_) {
          expectUsageError();
        });
      });

      test('dashed arg', () {
        var flagValue;
        return new FunctionScript(({bool dashedFlag}) {
          flagValue = dashedFlag;
        }).execute(['--dashed-flag']).then((_) {
          expect(flagValue, true);
        });
      });

      test('allowTrailingOptions should be false by default', () {
        var restValue, optionValue;
        return new FunctionScript((@Rest() rest, {var option}) {
          restValue = rest;
          optionValue = option;
        }).execute(['x', 'y', '--option', 'option']).then((_) {
          expect(restValue, ['x', 'y', '--option', 'option']);
          expect(optionValue, null);
        });
      });

      test('--help prevents command from executing', () {
        return new FunctionScript(() {
          _happened = true;
        }).execute(['--help']).then((_) {
          expect(_happened, false);
        });
      });

      SubCommandScriptTest withSubCommands({bool flag1}) {
        return new SubCommandScriptTest(flag1: flag1);
      }

      test('with sub-commands', () {
        return new FunctionScript(withSubCommands).execute(['--flag1', 'recursive2', '--flag2']);
      });

    });

    group('parser', () {
      test('for Option - valid input', () {
        var optionValue;
        return new FunctionScript(({@Option(parser: int.parse) int option}) {
          optionValue = option;
        }).execute(['--option', '123']).then((_) {
          expect(optionValue, 123);
        });
      });

      test('for Option - from type annotation', () {
        var optionValue;
        return new FunctionScript(({int option}) {
          optionValue = option;
        }).execute(['--option', '123']).then((_) {
          expect(optionValue, 123);
        });
      });

      test('for Option - invalid input throws', () {
        return new FunctionScript(({@Option(parser: int.parse) int option}) {
          _happened = true;
        }).execute(['--option', 'abc']).then((_) {
          expectUsageError();
        });
      });

      test('for Option - with allowMultiple', () {
        var optionValues;
        return new FunctionScript(({@Option(parser: int.parse, allowMultiple: true) List<int> option}) {
          optionValues = option;
        }).execute(['--option', '1', '--option', '2']).then((_) {
          expect(optionValues, [1, 2]);
        });
      });

      test('for Option - from List type annotation', () {
        var optionValues;
        return new FunctionScript(({List<int> option}) {
          optionValues = option;
        }).execute(['--option', '1', '--option', '2']).then((_) {
          expect(optionValues, [1, 2]);
        });
      });

      test('for Positional - valid input', () {
        var positionalValue;
        var restValue;
        return new FunctionScript((
            @Positional(parser: int.parse) int first,
            @Rest(parser: int.parse) List<int> rest) {
          positionalValue = first;
          restValue = rest;
        }).execute(['123', '4', '5', '6']).then((_) {
          expect(positionalValue, 123);
          expect(restValue, [4, 5, 6]);
        });
      });

      test('for Positional - from type annotation', () {
        var positionalValue;
        var restValue;
        return new FunctionScript((
            int first,
            List<int> rest) {
          positionalValue = first;
          restValue = rest;
        }).execute(['123', '4', '5', '6']).then((_) {
          expect(positionalValue, 123);
          expect(restValue, [4, 5, 6]);
        });
      });

      test('not called on default values', () {
        var optionValue;
        return new FunctionScript(({int option : 1}) {
          optionValue = option;
        }).execute([]).then((_) {
          expect(optionValue, 1);
        });
      });

      test('for Positional - invalid input throws', () {
        return new FunctionScript((@Positional(parser: int.parse) int first) {
          _happened = true;
        }).execute(['abc']).then((_) {
          expectUsageError();
        });
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
        return unit.execute(['command']).then((_) {
          expect(CommandScriptTest._commandHappened, isTrue);
          expect(CommandScriptTest._lastSeen.flag, false);
          expect(CommandScriptTest._lastSeen.option, 'default');
        });
      });

      test('args resolved', () {
        return unit.execute(['--flag', '--option', 'value', 'command']).then((result) {
          expect(CommandScriptTest._commandHappened, isTrue);
          expect(CommandScriptTest._lastSeen.flag, true);
          expect(CommandScriptTest._lastSeen.option, 'value');
          expect(result, 0);
        });
      });

      test('returns future result', () {
        return unit.execute(['future']).then((result) {
          expect(result, 0);
        });
      });

      test('rest', () {
        return unit.execute(['command', '1', '2']).then((_) {
          expect(CommandScriptTest._commandHappened, isTrue);
          expect(_lastSeenRest, ['1', '2']);
        });
      });

      test('bad base args', () {
        return unit.execute(['--bogusflag', '--bogusoption', 'value', 'command']).then((_) {
          expect(CommandScriptTest._commandHappened, isFalse);
        });
      });

      test('no command', () {
        return unit.execute([]).then((_) {
          expect(CommandScriptTest._commandHappened, isFalse);
        });
      });

      test('dashed command', () {
        return unit.execute(['dashed-command']).then((_) {
          expect(CommandScriptTest._dashedCommandHappened, isTrue);
        });
      });

      test('recursive sub-commands', () {
        return unit.execute(['recursive1', '--flag1', 'recursive2', '--flag2']);
      });

      group('allowTrailingOptions', () {

        test('should allow trailing options when true', () {
          return unit.execute(['command', 'positional', '--command-flag']).then((_) {
            expect(_lastSeenRest, ['positional']);
            expect(CommandScriptTest._lastSeenCommandFlag, isTrue);
          });
        });

        test('should not allow trailing options when false', () {
          return unit.execute(['no-trailing', 'positional', '--command-flag']).then((_) {
            expect(_lastSeenRest, ['positional', '--command-flag']);
            expect(CommandScriptTest._lastSeenCommandFlag, isNull);
          });
        });
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
  static bool _lastSeenCommandFlag;

  @Command(help: 'Test command with sub-commands', allowTrailingOptions: true)
  CommandScriptTest({this.flag: false, this.option: 'default'});

  @SubCommand()
  int command(@Rest() rest, {bool commandFlag}) {
    _lastSeen = this;
    _lastSeenRest = rest;
    _lastSeenCommandFlag = commandFlag;
    _commandHappened = true;
    return 0;
  }

  @SubCommand()
  Future<int> future() {
    return new Future<int>.value(0);
  }

  @SubCommand(allowTrailingOptions: false)
  noTrailing(@Rest() rest, {bool commandFlag}) {
    _lastSeen = this;
    _lastSeenRest = rest;
    _lastSeenCommandFlag = commandFlag;
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
