
part of ink;

class CallStyle {

  static const _EXAMPLE_COMMAND = 'foo';

  final String _name;

  static const CallStyle NORMAL = const CallStyle._('NORMAL');
  static const CallStyle SHEBANG = const CallStyle._('SHEBANG');
  static const CallStyle SHELL = const CallStyle._('SHELL');

  const CallStyle._(this._name);

  String formatCommand(String command) {
    switch(this) {
      case NORMAL: return 'dart $command.dart';
      case SHEBANG: return '$command.dart';
      case SHELL: return command;
    }
  }

  String get _example => formatCommand(_EXAMPLE_COMMAND);

  String toString() => '$_name call style, example: $_example';

}
