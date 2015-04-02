
library unscripted.usage;

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:path/path.dart' as path;
import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/util.dart';
import 'package:unscripted/src/call_style.dart';

/// Adds a standard --help (-h) option to [parser].
/// If [parser] has any sub-commands also add a help sub-command,
/// and recursively add help to all sub-commands' parsers.
class Usage {

  /// The name used to invoke this command.
  final String name = null;

  /// The parent command's usage.  This is null for root commands.
  final Usage parent = null;

  /// Whether to hide this usage.
  final bool hide = false;

  /// A simple description of what this script does, for use in help text.
  String description;

  final CallStyle callStyle = CallStyle.current;

  /// Whether to allow options after positional arguments.
  bool allowTrailingOptions;

  Usage();

  /// The parser associated with this usage.
  // TODO: Make private.
  ArgParser get parser {
    if(_parser == null) {
      _parser = _getParser();
    }
    return _parser;
  }
  ArgParser _getParser() {
    return new ArgParser(allowTrailingOptions: allowTrailingOptions);
  }

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

  Map<String, Option> _options = {};
  Map<String, Option> _optionsView;
  Map<String, Option> get options {
    if(_optionsView == null) {
      _optionsView = new UnmodifiableMapView(_options);
    }
    return _optionsView;
  }
  addOption(String name, Option option) {
    addOptionToParser(parser, name, option);
    _options[name] = option;
  }

  List<String> _commandPath;
  List<String> get commandPath {
    if(_commandPath == null) {
      var path = [];
      var usage = this;
      while(true) {
        if(usage.parent == null) {
          _commandPath = path.reversed.toList();
          break;
        }
        path.add(usage.name);
        usage = usage.parent;
      }
    }
    return _commandPath;
  }

  List<ArgExample> _examples = [];
  List<ArgExample> _examplesView;
  List<ArgExample> get examples {
    if(_examplesView == null) {
      _examplesView = new UnmodifiableListView(_examples);
    }
    return _examplesView;
  }
  addExample(ArgExample example) {
    _examples.add(example);
  }

  Map<String, Usage> _commands = {};
  Map<String, Usage> _commandsView;
  Map<String, Usage> get commands {
    if(_commandsView == null) {
      _commandsView = new UnmodifiableMapView(_commands);
    }
    return _commandsView;
  }
  Usage addCommand(String name, [SubCommand command]) {
    var hide = command != null && command.hide != null && command.hide;
    var allowTrailingOptions = (command != null && command.allowTrailingOptions != null) ?
        command.allowTrailingOptions :
        this.allowTrailingOptions;
    parser.addCommand(name, new ArgParser(allowTrailingOptions: allowTrailingOptions));
    return _commands[name] = new _SubCommandUsage(this, name, hide);
  }

  CommandInvocation validate(CommandInvocation commandInvocation) =>
      applyUsageToCommandInvocation(this, commandInvocation);

  CommandInvocation parse(List<String> arguments) {
    ArgResults results;
    try {
      results = parser.parse(arguments);
    } catch (e) {
      throw new UsageException(usage: this, cause: e);
    }

    return convertArgResultsToCommandInvocation(results, parser);
  }

  void _validate(CommandInvocation commandInvocation) {
    var actual = commandInvocation.positionals != null ?
        commandInvocation.positionals.length : 0;

    throwPositionalCountError(String expectation) {
      throw new UsageException(usage: this, cause: 'Received $actual positional command-line '
          'arguments, but $expectation.');
    }

    if(actual < minPositionals) {
      throwPositionalCountError('at least $minPositionals required');
    }

    if(maxPositionals != null && actual > maxPositionals) {
      throwPositionalCountError('at most $maxPositionals allowed');
    }
  }

  int get minPositionals {
    var min = positionals.length;
    if(rest != null && rest.required) {
      min++;
    }
    return min;
  }

  int get maxPositionals => rest == null ? positionals.length : null;

  Positional positionalAt(int index) {
    if(!index.isNegative && index < positionals.length) return positionals[index];
    if(rest != null) return rest;
    return null;
  }

}

class _SubCommandUsage extends Usage {

  final Usage parent;
  final String name;
  final bool hide;

  CallStyle get callStyle => parent.callStyle;
  bool get allowTrailingOptions => parser.allowTrailingOptions;

  _SubCommandUsage(this.parent, this.name, this.hide);

  ArgParser _getParser() => parent.parser.commands[name];
}

class CommandInvocation {

  final String name;
  final List positionals;
  final Map<String, dynamic> options;
  final CommandInvocation subCommand;

  CommandInvocation._(this.name, this.positionals, this.options, this.subCommand);
}

class UsageException {
  final Usage usage;
  final String arg;
  final cause;

  UsageException({this.usage, this.arg, this.cause});

  String toString() {
    var argMesage = arg == null ? '' : ': argument $arg';
    var callStyle = usage.callStyle;
    if(callStyle == CallStyle.NORMAL) callStyle = CallStyle.SHEBANG;
    var command = formatCallStyle(callStyle);
    return '$command: error$argMesage: $cause';
  }
}

CommandInvocation convertArgResultsToCommandInvocation(ArgResults results, ArgParser parser) {

  var positionals = results.rest;

  var options = results.options.fold({}, (options, optionName) {
    if (results.wasParsed(optionName)) {
      options[optionName] = results[optionName];
    }
    return options;
  });

  CommandInvocation subCommand;

  if(results.command != null) {
    subCommand =
        convertArgResultsToCommandInvocation(results.command, parser.commands[results.command.name]);
  }

  return new CommandInvocation._(results.name, positionals, options, subCommand);
}

CommandInvocation applyUsageToCommandInvocation(Usage usage, CommandInvocation invocation) {

  usage._validate(invocation);

  var positionalParams = usage.positionals;
  var positionalArgs = invocation.positionals;
  int restParameterIndex;

  if(usage.rest != null) {
    restParameterIndex = positionalParams.length;
    positionalArgs = positionalArgs.take(restParameterIndex).toList();
  }

  var positionalParsers =
      positionalParams.map((positional) => positional.parser);
  var positionalNames =
      positionalParams.map((positional) => positional.valueHelp);

  parseArg(parser, arg, name) {
    if(parser == null || arg == null) return arg;
    try {
      return parser(arg);
    } catch(e) {
      throw new UsageException(usage: usage, arg: name, cause: e);
    }
  }

  List zipParsedArgs(args, parsers, names) {
    return new IterableZip([args, parsers, names])
        .map((parts) => parseArg(parts[1], parts[0], parts[2]))
        .toList();
  }

  var positionals = zipParsedArgs(
      positionalArgs,
      positionalParsers,
      positionalNames);

  if(usage.rest != null) {
    var rawRest = invocation.positionals.skip(restParameterIndex);
    var rest = zipParsedArgs(
        rawRest,
        new Iterable.generate(rawRest.length, (_) => usage.rest.parser),
        new Iterable.generate(rawRest.length, (_) => usage.rest.valueHelp));
    positionals.add(rest);
  }

  var options = <String, dynamic> {};

  usage.options.forEach((optionName, option) {
    var resolvedOptionValue;
    if (!invocation.options.containsKey(optionName)) {
      resolvedOptionValue = option.defaultsTo;
    } else {
      var optionValue = invocation.options[optionName];
      parseValue(value) => parseArg(option.parser, value, optionName);
      resolvedOptionValue = optionValue is List ?
          new UnmodifiableListView(optionValue.map(parseValue)) :
          parseValue(optionValue);
    }
    options[optionName] = resolvedOptionValue;
  });

  CommandInvocation subCommand;

  if(invocation.subCommand != null) {
    subCommand =
        applyUsageToCommandInvocation(usage.commands[invocation.subCommand.name], invocation.subCommand);
  }

  return new CommandInvocation._(invocation.name, positionals, options, subCommand);
}

formatCallStyle(CallStyle callStyle) {
  var basename = path.basename(Platform.script.pathSegments.last);
  var extension = path.extension(basename);
  if (extension == '.snapshot') {
    basename = path.basenameWithoutExtension(basename);
    extension = path.extension(basename);
  }
  var commandName = path.basenameWithoutExtension(basename);
  switch(callStyle) {
    case CallStyle.NORMAL: return 'dart $commandName.dart';
    case CallStyle.SHEBANG: return '$commandName.dart';
    case CallStyle.SHELL: return commandName;
    case CallStyle.BAT: return '$commandName.bat';
  }
}
