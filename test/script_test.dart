
library script_test;

import 'package:unscripted/unscripted.dart';
import 'package:unittest/unittest.dart';

List _lastSeenRest;

main() {

  group('Script', () {

    bool _happened;

    setUp(() {
      _happened = false;
      _lastSeenRest = null;
    });

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

      test('rest from Rest', () {
        var firstValue;
        new FunctionScript((String first, @Rest() rest) {
          firstValue = first;
          _lastSeenRest = rest;
        }).execute(['first', 'second', 'third', 'fourth']);
        expect(firstValue, 'first');
        expect(_lastSeenRest, ['second', 'third', 'fourth']);
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

    });
  });
}

@Command(help: 'Test command with sub-commands')
class CommandScriptTest {
  final bool flag;
  final String option;

  static CommandScriptTest _lastSeen;
  static bool _commandHappened;
  static bool _dashedCommandHappened;

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
}
