
library unscripted.call_style;

import 'dart:io';

/// How the command is called on the command line.
class CallStyle {

  final String _name;

  static CallStyle current = !Platform.isWindows || Platform.environment['SHELL'] != null ?
      CallStyle.SHEBANG : CallStyle.NORMAL;

  /// Called with the dart executable.
  /// Example:
  ///     dart foo.dart ...
  static const CallStyle NORMAL = const CallStyle._('NORMAL');
  /// Called without the dart executable, such as by including a shebang
  /// at the beginning of the script.
  /// Example:
  ///     foo.dart ...
  static const CallStyle SHEBANG = const CallStyle._('SHEBANG');
  /// Called without the '.dart' file extension, similar to a shell command.
  /// Example:
  ///     foo ...
  static const CallStyle SHELL = const CallStyle._('SHELL');

  const CallStyle._(this._name);

}
