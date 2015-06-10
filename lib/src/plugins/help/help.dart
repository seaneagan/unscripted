
library unscripted.plugins.help;

import 'dart:convert';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:supports_color/supports_color.dart';

import '../../../unscripted.dart';
import '../../plugin.dart';
import '../../usage.dart';
import '../../util.dart';
import 'option_help.dart';
import 'pens.dart';
import 'util.dart';

part 'usage_formatter.dart';

const _HELP = 'help';

class Help extends Plugin {

  const Help();

  updateUsage(Usage usage) {

    usage.commands.values.forEach(updateUsage);

    if(!usage.options.containsKey(_HELP)) {
      usage.addOption(new Flag(
        name: _HELP,
        abbr: 'h',
        help: 'Print this usage information.',
        negatable: false));
    }

    if(usage.commands.isNotEmpty && !usage.commands.containsKey(_HELP)){
      // TODO: This should be an optional positional if/when that is supported.
      usage.addCommand(_HELP, new SubCommand(hide: true))..addPositional(new Positional(allowed: usage.commands.keys.toList()..remove(_HELP)));
    }
  }

  bool onParse(
      Usage usage,
      CommandInvocation commandInvocation,
      Map<String, String> environment,
      bool isWindows) {
    var path = _getHelpPath(commandInvocation);
    if(path != null) {
      var helpUsage = path
          .fold(usage, (usage, subCommand) =>
              usage.commands[subCommand]);
      _printHelp(helpUsage, null, isWindows);
      return false;
    }
    return true;
  }

  bool onError(
      Usage usage,
      error,
      bool isWindows) {
    _printHelp(usage, error, isWindows);
    exitCode = 2;
    return false;
  }

  /// Prints help for [helpUsage].  If [error] is not null, prints the help and
  /// error to [stderr].
  // TODO: Integrate with Loggers.
  _printHelp(Usage helpUsage, error, isWindows) {
    var isError = error != null;
    var sink = stdout;
    if(isError) {
      sink = stderr;
      sink.writeln();
      sink.writeln(errorPen(error.toString()));
    }
    sink.writeln(_getUsageFormatter(helpUsage, isWindows).format());
  }

  UsageFormatter _getUsageFormatter(Usage usage, bool isWindows) =>
      new TerminalUsageFormatter(usage, supportsColor);

  List<String> _getHelpPath(CommandInvocation commandInvocation) {
    var path = [];
    var subCommandInvocation = commandInvocation;
    while(true) {
      if(subCommandInvocation.options.containsKey(_HELP) &&
          subCommandInvocation.options[_HELP]) return path;
      if(subCommandInvocation.subCommand == null) return null;
      if(subCommandInvocation.subCommand.name == _HELP) {
        var helpCommand = subCommandInvocation.subCommand;
        if(helpCommand.positionals.isNotEmpty) {
          path.add(helpCommand.positionals.first);
        }
        return path;
      }
      subCommandInvocation = subCommandInvocation.subCommand;
      path.add(subCommandInvocation.name);
    }
    return path;
  }

}
