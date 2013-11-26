
part of ink;

ink(model) {
  if(model is Type) return new ClassScript(model);
  if(model is Function) return new FunctionScript(model);
  throw new ArgumentError('model must be a Type or Function');
}

/// A wrapper around a command line script.
///
/// Automatically adds a `--help` option to the given [parser]:
///
/// * `foo.dart --help`
/// * `foo.dart -h`
///
/// ... and supports sub-commands as well:
///
/// * `foo.dart help`
/// * `foo.dart command --help`
/// * `foo.dart help command`
///
/// The help output includes a [description].
///
/// When the script is [execute]d, if invalid options are passed, it will
/// display the help information.  On script failure, the [exitCode] will be
/// set to `1`.
abstract class Script {

  /// A simple description of what this script does, for use in help text.
  final String description;

  /// The parser associated with this script.
  ArgParser get parser {
    if(!_parserInitialized) {
      _parser = _getParser();
      _addHelp(_parser);
      _parserInitialized = true;
    }
    return _parser;
  }
  ArgParser _getParser() => _parser;
  ArgParser _parser;
  bool _parserInitialized = false;

  Script(this.description, this._parser);

  Script._({this.description});

  /// Executes this script.
  ///
  /// * Parses the [arguments].
  /// * On success passes the [ArgResults] to [handleResults].
  /// * On failure, outputs the error and help information.
  execute(List<String> arguments) {

    ArgResults results;

    try {
      results = _getResults(arguments);
    } catch(e) {
      print('$e\n');
      _printHelp();
      return;
    }

    if(_checkHelp(results)) return;
    handleResults(results);

  }

  ArgResults _getResults(List<String> arguments) =>
      parser.parse(arguments);

  /// Handles successfully parsed [results].
  handleResults(ArgResults results);

  /// Prints help information for this script.
  // TODO: Integrate with Loggers.
  _printHelp([List<String> path]) {
    var helpParser = parser;

    if(path != null) {
      helpParser = path.fold(parser, (curr, command) =>
          parser.commands[command]);
    }
    print(_getFullHelp(helpParser, description: description, path: path));
  }

  List<String> _getHelpPath(ArgResults results) {
    var path = [];
    var subResults = results;
    while(true) {
      if(subResults.options.contains(_HELP) && subResults[_HELP]) return path;
      if(subResults.command == null) return null;
      subResults = subResults.command;
      path.add(subResults.name);
    }
    return path;
  }

  bool _checkHelp(ArgResults results) {
    var path = _getHelpPath(results);
    if(path != null) {
      _printHelp(path);
      return true;
    }
    return false;
  }

  Map<String, Script> get subScripts {
    return parser.commands.keys.fold({}, (subScripts, name) {
      subScripts[name] = _getSubScript(name);
      return subScripts;
    });
  }

  Script _getSubScript(String name);
}

class _SubScript {

  final String _name;
  final Script _parent;

  ArgParser _getParser() => _parent.parser.commands[_name];

}

abstract class _DeclarationScript extends Script {

  DeclarationMirror get _declaration;

  MethodMirror get _method;

  String get description {
    Command command = _declaration.metadata
        .map((annotation) => annotation.reflectee)
        .firstWhere((metadata) =>
            metadata is Command, orElse: () => null);
    return command == null ? '' : command.help;
  }

  Script _getSubScript(String name) => new _Sub

  _getResults(List<String> arguments) {
    var results = super._getResults(arguments);

    _checkResults(results);

    return results;
  }

  Rest get __restAnnotation {
    var firstParameter = _method.parameters.firstWhere(
        (parameter) => !parameter.isOptional,
        orElse: () => null);
    if(firstParameter != null) {
      return firstParameter
          .metadata
          .map((metadata) => metadata.reflectee)
          .firstWhere(
              (annotation) => annotation is Rest,
              orElse: () => null);
    }
    return null;
  }

  Rest _restAnnotation;
  Rest get restAnnotation {
    if(_restAnnotation == null) {
      _restAnnotation = __restAnnotation;
    }
    return _restAnnotation;
  }

  _checkResults(ArgResults results) {
    if(restAnnotation != null) {
      var min = restAnnotation.min;
      var count = results.rest.length;
      if(min != null && count < min) {
        throw 'This script requires at least $min argument(s)'
            ', but received $count.';
      }
    }
  }

  _DeclarationScript() : super._();
}

class _SubFunctionScript extends FunctionScript with _SubScript {
  _SubFunctionScript()
}

class _SubClassScript extends FunctionScript with _SubScript {
  _SubClassScript()
}

/// A [Script] whose interface and behavior is defined by a [Function].
///
/// The function's parameters must be marked with a [bool] type annotation or a
/// [Flag] metadata annotation to mark them as a flag, or with a [String] or
/// [dynamic] type annotation or [Option] metadata annotation to mark them as an
/// option.
///
/// When [execute]d, the command line arguments are injected into their
/// corresponding function arguments.
class FunctionScript extends _DeclarationScript {

  final Function _function;

  MethodMirror get _declaration =>
      (reflect(_function) as ClosureMirror).function;

  MethodMirror get _method => _declaration;

  ArgParser _getParser() => _getParserFromFunction(_declaration);

  FunctionScript(this._function, {String description})
      : super();

  handleResults(ArgResults results) {
    var positionalParameterInfo = _getPositionalParameterInfo(_declaration);
    var restParameterIndex = positionalParameterInfo[1] ?
        positionalParameterInfo[0] :
        null;
    var invocation = new ArgResultsToInvocationConverter(
        restParameterIndex).convert(results);
    Function.apply(
        _function,
        invocation.positionalArguments,
        invocation.namedArguments);
  }
}

/// A [Script] whose interface and behavior is defined by a class.
///
/// The class must have an unnamed constructor, and it's parameters define the
/// top-level options for this script.  Methods of the class can be annotated
/// as [SubCommand]s.  The parameters of these methods define the sub-command's
/// options.
///
/// When [execute]d, the base command line arguments (before the command)
/// are injected into the their corresponding constructor arguments, to create
/// an instance of the class.  Then, the method corresponding to the
/// sub-command that was specified on the command line is invoked on the
/// instance.
///
/// If no sub-command was specified, then [onNoSubCommand] is invoked.
class ClassScript extends _DeclarationScript {

  Type _class;

  ClassMirror get _declaration => reflectClass(_class);

  MethodMirror get _method => _getUnnamedConstructor(_declaration);

  ArgParser _getParser() => _getParserFromClass(_class);

  ClassScript(this._class)
      : super();

  handleResults(ArgResults results) {
    var classMirror = _declaration;

    // Handle constructor.
    var constructorInvocation = new ArgResultsToInvocationConverter(
        _getRestParameterIndex(_getUnnamedConstructor(classMirror))).convert(results);
    var instanceMirror = classMirror.newInstance(
        const Symbol(''),
        constructorInvocation.positionalArguments,
        constructorInvocation.namedArguments);

    // Handle command.
    var commandResults = results.command;
    if(commandResults == null) {
      defaultCommand(results);
      return;
    }
    var commandName = commandResults.name;
    var commandSymbol = new Symbol(dashesToCamelCase.encode(commandName));
    var commandMethod = classMirror.declarations[commandSymbol] as MethodMirror;
    var commandConverter = new ArgResultsToInvocationConverter(
        _getRestParameterIndex(commandMethod), memberName: commandSymbol);
    var commandInvocation = commandConverter.convert(commandResults);
    instanceMirror.delegate(commandInvocation);
  }

  /// Called if no sub-command was provided.
  ///
  /// The default implementation treats this as an error, and prints help
  /// information.
  defaultCommand(ArgResults results) {
    print('A sub-command must be specified.\n');
    _printHelp();
  }

}
