
library unscripted.declaration_script;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import '../unscripted.dart';
import 'string_codecs.dart';
import 'usage.dart';
import 'util.dart';
import 'plugin.dart';
import 'plugins/help/help.dart';
import 'plugins/completion/completion.dart' as completion;
import 'plugins/completion/marker.dart';

abstract class ScriptImpl implements Script {

  Usage get usage;

  List<Plugin> get plugins;

  Future execute(
      List<String> arguments,
      {Map<String, String> environment,
       bool isWindows}) => new Future.sync(() {

    if (isWindows == null) isWindows = Platform.isWindows && Platform.environment['SHELL'] == null;

    return new Future.sync(() {
      var commandInvocation = usage.parse(arguments);
      var reversedPlugins = plugins.reversed;
      if (!reversedPlugins.every((plugin) => plugin.onParse(
          usage, commandInvocation, environment, isWindows))) return null;
      commandInvocation = usage.validate(commandInvocation);
      if (!reversedPlugins.every((plugin) => plugin.onValidate(
          usage, commandInvocation, environment, isWindows))) return null;
      return commandInvocation;
    })
    .catchError((e) {
      // TODO: ArgParser.parse throws FormatException which does not indicate
      // which sub-command was trying to be executed.
      var helpUsage = e is UsageException ? e.usage : usage;
      _handleUsageError(helpUsage, e, isWindows);
      // TODO: Rethrow to give visibility into usage errors as well?
    })
    .then((CommandInvocation commandInvocation) => commandInvocation == null
        ? null
        : _handleResults(commandInvocation, isWindows));
  });

  /// Handles successfully validated [commandInvocation].
  _handleResults(CommandInvocation commandInvocation, bool isWindows);

  _handleUsageError(Usage usage, error, bool isWindows) {
    plugins.every((plugin) => plugin.onError(usage, error, isWindows));
  }

}

abstract class DeclarationScript extends ScriptImpl {

  DeclarationMirror get _declaration;

  MethodMirror get _method;

  final Map<Usage, Map<String, String>> usageOptionParameterMap = {};
  final Map<Usage, Map<OptionGroup, String>> usageOptionGroupParameterMap = {};

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
      _usage = getUsageFromFunction(_method, this);
      plugins.forEach((plugin) => plugin.updateUsage(_usage));
    }
    return _usage;
  }
  Usage _usage;

  _handleResults(CommandInvocation commandInvocation, bool isWindows) {

    var topInvocation = convertCommandInvocationToInvocation(commandInvocation, _method, this, usage);

    var topResult = _getTopCommandResult(topInvocation);

    var result = _handleSubCommands(topResult, commandInvocation.subCommand, usage, isWindows);
    return result == null ? result : result.reflectee;
  }

  _getTopCommandResult(Invocation invocation);

  _handleSubCommands(InstanceMirror result, CommandInvocation commandInvocation, Usage usage, bool isWindows) {

    if (commandInvocation == null) {
      // TODO: Move this to an earlier UsageException instead ?
      if(usage != null && usage.commands.keys.any((commandName) => !['help', 'completion'].contains(commandName))) {
        _handleUsageError(
            usage,
            new UsageException(
                usage: usage,
                cause: 'Must specify a sub-command.'),
            isWindows);
        return null;
      } else {
        return result;
      }
    }

    var commandName = commandInvocation.name;
    var commandSymbol = new Symbol(dashesToCamelCase.encode(commandName));
    var classMirror = result.type;
    var methods = classMirror.instanceMembers;
    var commandMethod = methods[commandSymbol];
    var subUsage = usage.commands[commandInvocation.name];
    var invocation = convertCommandInvocationToInvocation(commandInvocation, commandMethod, this, subUsage, memberName: commandSymbol);
    var subResult = result.delegate(invocation);
    return _handleSubCommands(reflect(subResult), commandInvocation.subCommand, subUsage, isWindows);
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

