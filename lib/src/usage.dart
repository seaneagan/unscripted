
library unscripted.usage;

import 'dart:collection';
import 'dart:io';
import 'dart:convert';

import 'package:unmodifiable_collection/unmodifiable_collection.dart';
import 'package:sequence_zip/sequence_zip.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/util.dart';

part 'usage_formatter.dart';

/// Adds a standard --help (-h) option to [parser].
/// If [parser] has any sub-commands also add a help sub-command,
/// and recursively add help to all sub-commands' parsers.
class Usage {

  /// Name.
  String get name {
    if(commandPath.isNotEmpty) return commandPath.last;
    return null;
  }

  /// A simple description of what this script does, for use in help text.
  String description;

  CallStyle callStyle = CallStyle.NORMAL;

  // TODO: Make public ?
  bool _allowTrailingOptions = false;

  Usage();

  /// The parser associated with this usage.
  ArgParser get parser {
    if(_parser == null) {
      _parser = _getParser();
      _addHelpFlag(_parser);
    }
    return _parser;
  }
  ArgParser _getParser() => new ArgParser();
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

  _addHelpFlag(ArgParser parser) =>
      addOption(HELP, new Flag(
          abbr: 'h',
          help: 'Print this usage information.',
          negatable: false));


  List<String> get commandPath => [];
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
  Usage addCommand(String name) {
    parser.addCommand(name);
    var command = _commands[name] = new _SubCommandUsage(this, name);
    if(name != HELP && !commands.keys.contains(HELP)) {
      addCommand(HELP);
    }
    return command;
  }

  ArgResults validate(List<String> arguments) {

    var results = parser.parse(arguments, allowTrailingOptions: _allowTrailingOptions);

    // Don't validate if help is requested.
    var shouldValidate = getHelpPath(results) == null;

    var commandInvocation = convertArgResultsToCommandInvocation(this, results, shouldValidate);

    return results;
  }
}

class _SubCommandUsage extends Usage {

  final Usage parent;
  final String _subCommandName;

  CallStyle get callStyle => parent.callStyle;

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

class CommandInvocation {

  final String name;
  final List positionals;
  final List rest;
  final Map<String, dynamic> options;
  final CommandInvocation subCommand;

  CommandInvocation._(this.name, this.positionals, this.rest, this.options, this.subCommand);
}

CommandInvocation convertArgResultsToCommandInvocation(Usage usage, ArgResults results, bool shouldValidate) {

  var positionalParams = usage.positionals;
  var positionalArgs = results.rest;
  int restParameterIndex;

  if(usage.rest != null) {
    restParameterIndex = positionalParams.length;
    positionalArgs = positionalArgs.take(restParameterIndex).toList();
  }

  if(shouldValidate) {

    var actual = results.rest.length;
    int max;
    var min = positionalParams.length;
    if(usage.rest == null) {
      max = positionalParams.length;
    } else if(usage.rest.min != null) {
      min += usage.rest.min;
    }

    throwPositionalCountError(String expectation) {
      throw new FormatException('Received $actual positional command-line '
          'arguments, but $expectation.');
    }

    if(actual < min) {
      throwPositionalCountError('at least $min required');
    }

    if(max != null && actual > max) {
      throwPositionalCountError('at most $max allowed');
    }
  }

  var positionalParsers =
      positionalParams.map((positional) => positional.parser);

  parseArg(parser, arg) {
    print('parser: $parser, arg: $arg');
    return (parser == null || arg == null) ? arg : parser(arg);
  }

  List zipParsedArgs(args, parsers) {
    return new IterableZip(
        [args,
         parsers])
    .map((parts) => parseArg(parts[1], parts[0]))
      .toList();
  }

  var positionals = zipParsedArgs(positionalArgs, positionalParsers);
  List rest;

  if(usage.rest != null) {
    var rawRest = results.rest.skip(restParameterIndex);
    var restParser = usage.rest.parser;
    rest = zipParsedArgs(rawRest, new Iterable.generate(rawRest.length, (_) => restParser));
  }

  var options = <String, dynamic> {};

  usage.options
      .forEach((optionName, option) {
        if(optionName == HELP) return;
        var optionValue = results[optionName];
        options[optionName] = parseArg(option.parser, optionValue);
      });

  CommandInvocation subCommand;

  if(results.command != null) {
    subCommand =
        convertArgResultsToCommandInvocation(usage.commands[results.command.name], results.command, shouldValidate);
  }

  return new CommandInvocation._(results.name, positionals, rest, options, subCommand);
}
