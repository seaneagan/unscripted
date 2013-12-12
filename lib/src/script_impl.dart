
library unscripted.declaration_script;

import 'dart:mirrors';

import 'package:args/args.dart' show ArgResults;
import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/string_codecs.dart';
import 'package:unscripted/src/args_codec.dart';
import 'package:unscripted/src/util.dart';

abstract class _DeclarationScript extends Script {

  DeclarationMirror get _declaration;

  MethodMirror get _method;

  _DeclarationScript();
}

class FunctionScript extends _DeclarationScript {

  final Function _function;

  MethodMirror get _declaration =>
      (reflect(_function) as ClosureMirror).function;

  MethodMirror get _method => _declaration;

  Usage get usage => getUsageFromFunction(_declaration);

  FunctionScript(this._function, {String description})
      : super();

  handleResults(ArgResults results) {
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

class ClassScript extends _DeclarationScript {

  Type _class;

  ClassMirror get _declaration => reflectClass(_class);

  MethodMirror get _method => getUnnamedConstructor(_declaration);

  Usage get usage => getUsageFromClass(_class);

  ClassScript(this._class)
      : super();

  handleResults(ArgResults results) {
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
      defaultCommand(results);
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
  defaultCommand(ArgResults results) {
    print('A sub-command must be specified.\n');
    printHelp();
  }

}
