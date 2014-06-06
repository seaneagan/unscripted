
library unscripted.plugins.completion.command_line;

import 'dart:io';

import 'util.dart';

class CommandLine {

  final String line;
  final int cursor;
  final int wordIndex;
  final Iterable<String> args;

  Iterable<String> get words => args.map(unescape);
  String get word => words.elementAt(wordIndex);
  String get partialLine => line.substring(0, cursor);
  Iterable<String> get partialWords {
    if(_partialWords == null) {
      if(words.isEmpty) {
        _partialWords = const [];
      } else {
        _partialWords = words.take(wordIndex).toList()..add(partialWord);
      }
    }
    return _partialWords;
  }
  Iterable<String> _partialWords;
  String get partialWord {
    // Figure out where in that last word the point is.
    var argWord = args.elementAt(wordIndex);
    var i = argWord.length;
    while (argWord.substring(0, i) !=
        partialLine.substring(partialLine.length - i) && i > 0) {
      i--;
    }
    return unescape(argWord.substring(0, i));
  }

  /// Reads the [CommandLine] from the `COMP_CWORD`, `COMP_LINE`, and
  /// `COMP_POINT` environment variables.
  ///
  /// Returns null if any of those environment variables are not defined.
  ///
  /// Environment variables are found in [Platform.environment], or
  /// [environment] if not null, which is useful for testing.
  factory CommandLine(List<String> args, {Map<String, String> environment}) {
    if(environment == null) environment = Platform.environment;
    if(!_inEnvironment(environment)) return null;
    var line = environment['COMP_LINE'];
    var cursor = int.parse(environment['COMP_POINT']);
    var wordIndex = int.parse(environment['COMP_CWORD']) - 1;
    var realArgs = args.sublist(1);
    if(line.endsWith(' ')) realArgs.add('');

    return new CommandLine._(
        line,
        cursor,
        realArgs,
        wordIndex);
  }

  static bool _inEnvironment(Map<String, String> environment) =>
      const ['COMP_CWORD', 'COMP_LINE', 'COMP_POINT']
          .every(environment.keys.contains);

  CommandLine._(this.line, this.cursor, this.args, this.wordIndex);

}
