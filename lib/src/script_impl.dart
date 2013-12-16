
library unscripted.declaration_script;

import 'dart:mirrors';

import 'package:args/args.dart' show ArgResults;
import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/string_codecs.dart';
import 'package:unscripted/src/args_codec.dart';
import 'package:unscripted/src/usage.dart';
import 'package:unscripted/src/util.dart';

abstract class ScriptImpl implements Script {

  Usage get usage;

  UsageFormatter getUsageFormatter(Usage usage) =>
      new TerminalUsageFormatter(usage);

  execute(List<String> arguments) {

    ArgResults results;

    try {
      results = usage.validate(arguments);
    } catch(e) {
      print('$e\n');
      _printHelp();
      return;
    }

    if(_checkHelp(results)) return;
    _handleResults(results);

  }

  /// Handles successfully parsed [results].
  _handleResults(ArgResults results);

  /// Prints help information for the associated command or sub-command thereof
  /// at [commandPath].
  // TODO: Integrate with Loggers.
  _printHelp([List<String> commandPath]) {
    var helpUsage = (commandPath == null ? [] : commandPath)
        .fold(usage, (usage, subCommand) =>
            usage.commands[subCommand]);
    print(getUsageFormatter(helpUsage).format());
  }

  bool _checkHelp(ArgResults results) {
    var path = getHelpPath(results);
    if(path != null) {
      _printHelp(path);
      return true;
    }
    return false;
  }
}

abstract class DeclarationScript extends ScriptImpl {

  DeclarationMirror get _declaration;

  MethodMirror get _method;

  DeclarationScript();
}

class FunctionScript extends DeclarationScript {

  final Function _function;

  MethodMirror get _declaration =>
      (reflect(_function) as ClosureMirror).function;

  MethodMirror get _method => _declaration;

  Usage get usage => getUsageFromFunction(_declaration);

  FunctionScript(this._function, {String description})
      : super();

  _handleResults(ArgResults results) {
    var positionalParameterInfo = getPositionalParameterInfo(_declaration);
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

class ClassScript extends DeclarationScript {

  Type _class;

  ClassMirror get _declaration => reflectClass(_class);

  MethodMirror get _method => getUnnamedConstructor(_declaration);

  Usage get usage => getUsageFromClass(_class);

  ClassScript(this._class)
      : super();

  _handleResults(ArgResults results) {
    var classMirror = _declaration;

    // Handle constructor.
    var constructorInvocation = new ArgResultsToInvocationConverter(
        getRestParameterIndex(getUnnamedConstructor(classMirror))).convert(results);

    var instanceMirror = classMirror.newInstance(
        const Symbol(''),
        constructorInvocation.positionalArguments,
        constructorInvocation.namedArguments);

    // Handle command.
    var commandResults = results.command;
    if(commandResults == null) {
      _defaultCommand(results);
      return;
    }
    var commandName = commandResults.name;
    var commandSymbol = new Symbol(dashesToCamelCase.encode(commandName));
    var commandMethod = classMirror.declarations[commandSymbol] as MethodMirror;
    var commandConverter = new ArgResultsToInvocationConverter(
        getRestParameterIndex(commandMethod), memberName: commandSymbol);
    var commandInvocation = commandConverter.convert(commandResults);
    instanceMirror.delegate(commandInvocation);
  }

  /// Called if no sub-command was provided.
  ///
  /// The default implementation treats this as an error, and prints help
  /// information.
  _defaultCommand(ArgResults results) {
    print('A sub-command must be specified.\n');
    _printHelp();
  }

}
