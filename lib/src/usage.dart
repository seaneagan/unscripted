
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

  addPositional(String help) {
    _positionals.add(new Positional(help: help));
  }

  List<Positional> _positionals = [];
  List<Positional> _positionalsView;
  List<Positional> get positionals {
    if(_positionalsView == null) {
      _positionalsView = new UnmodifiableListView(_positionals);
    }
    return _positionalsView;
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

    // Ignore other arguments if user wants help.
    if(_getHelpPath(results) != null) return;

    // Check positional count.
    var min = _positionals.length +
        (rest == null ? 0 : rest.min == null ? 0 : rest.min);
    var count = results.rest.length;
    if(count < min) {
      List<_Help> positionalHelp = _positionals.toList();
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
