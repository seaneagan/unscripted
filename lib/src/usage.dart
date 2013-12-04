
part of ink;

/// Adds a standard --help (-h) option to [parser].
/// If [parser] has any sub-commands also add a help sub-command,
/// and recursively add help to all sub-commands' parsers.
class Usage {

  /// A simple description of what this script does, for use in help text.
  String description;

  Rest rest;

  CallStyle callStyle = CallStyle.NORMAL;

  // TODO: Make public ?
  bool _allowTrailingOptions = false;

  /// The parser associated with this usage.
  ArgParser get parser {
    if(_parser == null) {
      _parser = _getParser();
    }
    return _parser;
  }
  ArgParser _getParser() {
    var parser = new ArgParser();
    _addHelpFlag(parser);
    return parser;
  }

  _addHelpFlag(ArgParser parser) {
    parser.addFlag(
        _HELP,
        abbr: 'h',
        help: 'Print this usage information.', negatable: false);
  }

  ArgParser _parser;

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
    _addHelpFlag(command.parser);
    if(name != _HELP && !commands.keys.contains(_HELP)) {
      addCommand(_HELP);
    }
    return command;
  }

  ArgResults validate(List<String> arguments) {
    var results = parser.parse(arguments, allowTrailingOptions: _allowTrailingOptions);

    _checkResults(results);

    return results;
  }

  _checkResults(ArgResults results) {
    if(rest != null) {
      var min = rest.min;
      var count = results.rest.length;
      if(min != null && count < min) {
        throw 'This script requires at least $min argument(s)'
            ', but received $count.';
      }
    }
  }

}

class _SubCommandUsage extends Usage {

  final Usage parent;
  final String _subCommandName;

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
