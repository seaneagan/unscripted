
part of ink;

class Usage {

  /// The name by which the script is referenced on the command line.
  String get name => basename(Platform.script.path);

  /// A simple description of what this script does, for use in help text.
  String description;

  Rest rest;

  // TODO: Make public ?
  bool _allowTrailingOptions = false;

  /// The parser associated with this usage.
  ArgParser get parser {
    if(!_parserInitialized) {
      _parser = _getParser();
      _addHelp(_parser);
      _parserInitialized = true;
    }
    return _parser;
  }
  ArgParser _getParser() => new ArgParser();
  ArgParser _parser;
  bool _parserInitialized = false;

  Usage();

  List<String> get commandPath => [];
  List<ArgExample> examples = [];
  Map<String, Usage> commands = {};

  addExample(String example, {String help}) {
    examples.add(new ArgExample(example, help: help));
  }

  addCommand(String name) {
    parser.addCommand(name);
    return commands[name] = new _SubCommandUsage(this, name);
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

class ArgExample {

  final String example;
  final String help;

  ArgExample(this.example, {String help})
      : this.help = help == null ? '' : help;
}
