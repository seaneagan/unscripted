
library unscripted.declaration_script;

import 'dart:mirrors';

import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/string_codecs.dart';
import 'package:unscripted/src/usage.dart';
import 'package:unscripted/src/util.dart';

abstract class ScriptImpl implements Script {

  Usage get usage;

  UsageFormatter getUsageFormatter(Usage usage) =>
      new TerminalUsageFormatter(usage);

  execute(List<String> arguments) {

    CommandInvocation commandInvocation;

    try {
      commandInvocation = usage.validate(arguments);
    } catch(e) {
      print('$e\n');
      _printHelp();
      return;
    }

    if(_checkHelp(commandInvocation)) return;
    _handleResults(commandInvocation);

  }

  /// Handles successfully validated [commandInvocation].
  _handleResults(CommandInvocation commandInvocation);

  /// Prints help information for the associated command or sub-command thereof
  /// at [commandPath].
  // TODO: Integrate with Loggers.
  _printHelp([List<String> commandPath]) {
    var helpUsage = (commandPath == null ? [] : commandPath)
        .fold(usage, (usage, subCommand) =>
            usage.commands[subCommand]);
    print(getUsageFormatter(helpUsage).format());
  }

  bool _checkHelp(CommandInvocation commandInvocation) {
    var path = commandInvocation.helpPath;
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

  _handleResults(CommandInvocation commandInvocation) {
    var invocation = convertCommandInvocationToInvocation(commandInvocation, _method);
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

  _handleResults(CommandInvocation commandInvocation) {
    var classMirror = _declaration;

    // Handle constructor.
    var constructorInvocation = convertCommandInvocationToInvocation(commandInvocation, _method);

    var instanceMirror = classMirror.newInstance(
        const Symbol(''),
        constructorInvocation.positionalArguments,
        constructorInvocation.namedArguments);

    // Handle command.
    var commandResults = commandInvocation.subCommand;
    if(commandResults == null) {
      _defaultCommand(commandInvocation);
      return;
    }
    var commandName = commandResults.name;
    var commandSymbol = new Symbol(dashesToCamelCase.encode(commandName));
    var commandMethod = _declaration.declarations[commandSymbol] as MethodMirror;
    var subCommandInvocation = convertCommandInvocationToInvocation(commandInvocation.subCommand, commandMethod, memberName: commandSymbol);
    instanceMirror.delegate(subCommandInvocation);
  }

  /// Called if no sub-command was provided.
  ///
  /// The default implementation treats this as an error, and prints help
  /// information.
  _defaultCommand(CommandInvocation commandInvocation) {
    print('A sub-command must be specified.\n');
    _printHelp();
  }

}
