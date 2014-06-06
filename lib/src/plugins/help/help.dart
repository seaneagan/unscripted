
library unscripted.plugins.help;

import 'dart:convert';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:unscripted/unscripted.dart';
import 'package:unscripted/src/plugin.dart';
import 'package:unscripted/src/usage.dart';
import 'package:quiver/strings.dart';

part 'usage_formatter.dart';

const _HELP = 'help';

class Help extends Plugin {

  const Help();

  updateUsage(Usage usage) {

    usage.commands.values.forEach(updateUsage);

    if(!usage.options.containsKey(_HELP)) {
      usage.addOption(_HELP, new Flag(
        abbr: 'h',
        help: 'Print this usage information.',
        negatable: false));
    }

    if(usage.commands.isNotEmpty && !usage.commands.containsKey(_HELP)){
      usage.addCommand(_HELP);
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
      sink.writeln(error);
      sink.writeln();
    }
    sink.writeln(_getUsageFormatter(helpUsage, isWindows).format());
  }

  UsageFormatter _getUsageFormatter(Usage usage, bool isWindows) =>
      new TerminalUsageFormatter(usage, shouldDisableColor(isWindows));

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

// TODO: May need to also disable when testing help formatting output.
bool shouldDisableColor(bool isWindows) => isWindows || !stdout.hasTerminal;
