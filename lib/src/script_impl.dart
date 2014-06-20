
library unscripted.declaration_script;

import 'dart:io';
import 'dart:mirrors';

import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/string_codecs.dart';
import 'package:unscripted/src/usage.dart';
import 'package:unscripted/src/util.dart';
import 'package:unscripted/src/plugin.dart';
import 'package:unscripted/src/plugins/help/help.dart';
import 'package:unscripted/src/plugins/completion/completion.dart' as completion;
import 'package:unscripted/src/plugins/completion/marker.dart';

abstract class ScriptImpl implements Script {

  Usage get usage;

  List<Plugin> get plugins;

  execute(
      List<String> arguments,
      {Map<String, String> environment,
       bool isWindows}) {

    if(isWindows == null) isWindows = Platform.isWindows && Platform.environment['SHELL'] == null;

    CommandInvocation commandInvocation;

    try {
      commandInvocation = usage.parse(arguments);
      var reversedPlugins = plugins.reversed;
      if(!reversedPlugins.every((plugin) => plugin.onParse(usage, commandInvocation, environment, isWindows))) return;
      commandInvocation = usage.validate(commandInvocation);
      if(!reversedPlugins.every((plugin) => plugin.onValidate(usage, commandInvocation, environment, isWindows))) return;
    } catch (e) {
      // TODO: ArgParser.parse throws FormatException which does not indicate
      // which sub-command was trying to be executed.
      var helpUsage = e is UsageException ? e.usage : usage;
      _handleUsageError(helpUsage, e, isWindows);
      return;
    }

    _handleResults(commandInvocation, isWindows);

  }

  /// Handles successfully validated [commandInvocation].
  _handleResults(CommandInvocation commandInvocation, bool isWindows);

  _handleUsageError(Usage usage, error, bool isWindows) {
    plugins.every((plugin) => plugin.onError(usage, error, isWindows));
  }

}

abstract class DeclarationScript extends ScriptImpl {

  DeclarationMirror get _declaration;

  MethodMirror get _method;

  List<Plugin> get plugins {
    if(_plugins == null) {
      _plugins = [];
      var command = getFirstMetadataMatch(
          _method, (metadata) => metadata is Command);
      if(command != null && command.plugins != null) {
        command.plugins.forEach((plugin) {
          if(plugin is Completion) {
            _plugins.add(new completion.Completion());
          } else {
            throw 'Unrecognized plugin: $plugin';
          }
        });
      }
      // Must add help last, so that it can know about any sub-commands it
      // needs to add help for.
      _plugins.add(const Help());
    }
    return _plugins;
  }
  List<Plugin> _plugins;

  DeclarationScript();

  Usage get usage {
    if(_usage == null) {
      _usage = getUsageFromFunction(_method);
      plugins.forEach((plugin) => plugin.updateUsage(_usage));
    }
    return _usage;
  }
  Usage _usage;

  _handleResults(CommandInvocation commandInvocation, bool isWindows) {

    var topInvocation = convertCommandInvocationToInvocation(commandInvocation, _method);

    var topResult = _getTopCommandResult(topInvocation);

    _handleSubCommands(topResult, commandInvocation.subCommand, usage, isWindows);
  }

  _getTopCommandResult(Invocation invocation);

  _handleSubCommands(InstanceMirror result, CommandInvocation commandInvocation, Usage usage, bool isWindows) {

    if(commandInvocation == null) {
      // TODO: Move this to an earlier UsageException instead ?
      if(usage != null && usage.commands.keys.any((commandName) => !['help', 'completion'].contains(commandName))) {
        _handleUsageError(
            usage,
            new UsageException(
                usage: usage,
                cause: 'Must specify a sub-command.'),
            isWindows);
      }
      return;
    }

    var commandName = commandInvocation.name;
    var commandSymbol = new Symbol(dashesToCamelCase.encode(commandName));
    var classMirror = result.type;
    var methods = classMirror.instanceMembers;
    var commandMethod = methods[commandSymbol];
    var invocation = convertCommandInvocationToInvocation(commandInvocation, commandMethod, memberName: commandSymbol);
    var subResult = result.delegate(invocation);
    Usage subUsage;
    if(commandInvocation.subCommand != null) subUsage = usage.commands[commandInvocation.subCommand.name];
    _handleSubCommands(reflect(subResult), commandInvocation.subCommand, subUsage, isWindows);
  }

}

class FunctionScript extends DeclarationScript {

  final Function _function;

  MethodMirror get _declaration =>
      (reflect(_function) as ClosureMirror).function;

  MethodMirror get _method => _declaration;

  FunctionScript(this._function) : super();

  _getTopCommandResult(Invocation invocation) => reflect(Function.apply(
      _function,
      invocation.positionalArguments,
      invocation.namedArguments));
}

class ClassScript extends DeclarationScript {

  Type _class;

  ClassMirror get _declaration => reflectClass(_class);

  MethodMirror get _method => getUnnamedConstructor(_declaration);

  ClassScript(this._class) : super();

  _getTopCommandResult(Invocation invocation) => _declaration.newInstance(
      const Symbol(''),
      invocation.positionalArguments,
      invocation.namedArguments);
}
