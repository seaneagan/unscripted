
library unscripted.usage;

import 'dart:collection';
import 'dart:io';

import 'package:unmodifiable_collection/unmodifiable_collection.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/args_codec.dart';
import 'package:unscripted/src/util.dart';

part 'usage_formatter.dart';

/// Adds a standard --help (-h) option to [parser].
/// If [parser] has any sub-commands also add a help sub-command,
/// and recursively add help to all sub-commands' parsers.
class Usage {

  /// A simple description of what this script does, for use in help text.
  String description;

  CallStyle callStyle = CallStyle.NORMAL;

  // TODO: Make public ?
  bool _allowTrailingOptions = false;

  /// The parser associated with this usage.
  ArgParser get parser {
    if(_parser == null) {
      _parser = _getParser();
      _addHelpFlag(_parser);
    }
    return _parser;
  }
  ArgParser _getParser() => new ArgParser();
  ArgParser _parser;

  // Positionals

  addPositional(Positional positional) {
    _positionals.add(positional);
  }

  List<Positional> _positionals = [];
  List<Positional> _positionalsView;
  List<Positional> get positionals {
    if(_positionalsView == null) {
      _positionalsView = new UnmodifiableListView(_positionals);
    }
    return _positionalsView;
  }

  Rest rest;

  // Options

  addOption(String name, Option option) {
    addOptionToParser(parser, name, option);
    _options[name] = option;
  }
  Map<String, Option> _options = {};
  Map<String, Option> _optionsView;
  Map<String, Option> get options {
    if(_optionsView == null) {
      _optionsView = new UnmodifiableMapView(_options);
    }
    return _optionsView;
  }

  _addHelpFlag(ArgParser parser) =>
      addOption(HELP, new Flag(
          abbr: 'h',
          help: 'Print this usage information.',
          negatable: false));

  Usage();

  List<String> get commandPath => [];
  List<ArgExample> examples = [];
  Map<String, Usage> commands = {};

  addExample(ArgExample example) {
    examples.add(example);
  }

  Usage addCommand(String name) {
    parser.addCommand(name);
    var command = commands[name] = new _SubCommandUsage(this, name);
    if(name != HELP && !commands.keys.contains(HELP)) {
      addCommand(HELP);
    }
    return command;
  }

  ArgResults validate(List<String> arguments) {
    var results = parser.parse(arguments, allowTrailingOptions: _allowTrailingOptions);

    _checkResults(results);

    return results;
  }

  _checkResults(ArgResults results) {

    // Ignore other arguments if user wants help.
    if(getHelpPath(results) != null) return;

    // Check positional count.
    var min = _positionals.length +
        (rest == null ? 0 : rest.min == null ? 0 : rest.min);
    var count = results.rest.length;
    if(count < min) {
      List<Help> positionalHelp = _positionals.toList();
      if(rest != null) positionalHelp.add(rest);

      var missingPositional = positionalHelp[count].help;

      var message = missingPositional == null ?
          'This script requires at least $min positional argument(s)'
          ', but received $count.' :
          'Missing the <$missingPositional> positional ';

      throw new FormatException(message);
    }
  }

}

class _SubCommandUsage extends Usage {

  final Usage parent;
  final String _subCommandName;

  CallStyle get callStyle => parent.callStyle;

  _SubCommandUsage(this.parent, this._subCommandName);

  List<String> _path;
  List<String> get commandPath {
    if(_path == null) {
      _path = parent.commandPath.toList()..add(_subCommandName);
    }
    return _path;
  }

  ArgParser _getParser() => parent.parser.commands[_subCommandName];
}
