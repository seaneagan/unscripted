
library unscripted.completion;

import 'dart:async';
import 'dart:io';

import '../../../unscripted.dart';
import '../../usage.dart';
import '../../plugin.dart';
import '../../call_style.dart';
import 'command_line.dart';
import 'completion_script.dart';
import 'usage_completion.dart';
import 'util.dart';

class Completion extends Plugin {

  const Completion();

  CompletionAdapter _getAdapter(Usage usage) => new CompletionAdapter(usage);

  updateUsage(Usage usage) {
    _getAdapter(usage).updateUsage(usage);
  }

  bool onParse(Usage usage, CommandInvocation commandInvocation, Map<String,
      String> environment, bool isWindows) {
    return _getAdapter(usage).onParse(usage, commandInvocation, environment,
        isWindows);
  }
}

abstract class CompletionAdapter {

  factory CompletionAdapter(Usage usage) {
    if (usage.commands.isEmpty) return new CompletionOptionAdapter();
    return new CompletionCommandAdapter();
  }

  CompletionAdapter._();

  updateUsage(Usage usage);
  String _formatInterfaceToken(String name);
  bool onParse(Usage usage, CommandInvocation commandInvocation, Map<String,
      String> environment, bool isWindows) {
    var completionCommandInvocation = _getCompletionCommandInvocation(commandInvocation);
    if (completionCommandInvocation != null) {
      if (usage.callStyle == CallStyle.NORMAL) {
        var ENOTSUP = 252;
        exitCode = ENOTSUP;
        throw new UnsupportedError(
            "${formatCallStyle(CallStyle.SHEBANG)} completion not supported on windows");
      }
      _complete(usage, completionCommandInvocation,
          environment: environment, isWindows: isWindows);
      return false;
    }
    return true;
  }
  CommandInvocation _getCompletionCommandInvocation(CommandInvocation
      commandInvocation);
  Future _complete(Usage usage, CommandInvocation commandInvocation, {bool
      isWindows, Map<String, String> environment}) => new Future.sync(() {

    if (environment == null) environment = Platform.environment;
    var args = commandInvocation.positionals;
    var commandLine = new CommandLine(args, environment: environment);
    if (commandLine == null) {
      _handleCompletionScript(usage, commandInvocation);
    } else {
      // "Plumbing mode"
      _getCompletionOutput(usage, commandLine).then((String output) {
        if (output.isNotEmpty) {
          print(output);
        }
      });
    }
  });
  _handleCompletionScript(Usage usage, CommandInvocation commandInvocation) {
    var commandToComplete = formatCallStyle(usage.callStyle);
    var installationCommand = _getInstallationName(commandInvocation);
    var completionSyntax = '${_getCompletionSyntax()}${_completionSeparator}print';
    switch (installationCommand) {
      case 'print':
        print(getScriptOutput(commandToComplete, completionSyntax));
        break;
      case 'install':
        installScript(commandToComplete, completionSyntax);
        break;
      case 'uninstall':
        uninstallScript(commandToComplete, completionSyntax);
        break;
    }
  }
  String _getCompletionSyntax() => _formatInterfaceToken(_COMPLETION);
  String get _completionSeparator;
  String _getInstallationName(CommandInvocation commandInvocation);
}

class CompletionCommandAdapter extends CompletionAdapter {

  CompletionCommandAdapter() : super._();

  updateUsage(Usage usage) {
    var completionCommand = usage.addCommand(_COMPLETION)
        ..description = 'Tab completion for this command.'
        ..rest = new Rest(help: 'Used internally by the completion script');

    _installationNamesHelp.forEach((name, help) {
      completionCommand.addCommand(name)..description = help;
    });
  }

  String _formatInterfaceToken(String name) => name;

  CommandInvocation _getCompletionCommandInvocation(CommandInvocation
      commandInvocation) {
    var baseCompletionCommand = commandInvocation.subCommand;
    if (baseCompletionCommand != null && baseCompletionCommand.name == _COMPLETION) {
      var subCompletionCommand = baseCompletionCommand.subCommand;
      return subCompletionCommand == null ? baseCompletionCommand : subCompletionCommand;
    }
    return null;
  }
  String _getInstallationName(CommandInvocation commandInvocation) {
    if(commandInvocation.name == _COMPLETION) return 'print';
    return commandInvocation.name;
  }
  final String _completionSeparator = ' ';
}

class CompletionOptionAdapter extends CompletionAdapter {

  CompletionOptionAdapter() : super._();

  updateUsage(Usage usage) {
    usage.addOption(new Option(
        name: _COMPLETION,
        allowed: _installationNamesHelp,
        help: 'Tab completion for this command.'));
  }

  String _formatInterfaceToken(String name) => '--$name';

  CommandInvocation _getCompletionCommandInvocation(CommandInvocation
      commandInvocation) {
      return commandInvocation.options[_COMPLETION] == null ?
          null :
          commandInvocation;
  }
  String _getInstallationName(CommandInvocation commandInvocation) {
    return commandInvocation.options[_COMPLETION];
  }
  final String _completionSeparator = '=';
}

Future<String> _getCompletionOutput(Usage usage, CommandLine commandLine) {
  return getUsageCompletions(usage, commandLine).then((completions) {
    completions = _filterCompletions(commandLine.partialWord,
        _expandCompletions(completions));
    return completions.join('\n');
  });
}

Iterable<String> _expandCompletions(Iterable completions) => completions.map((c)
    => (c is Iterable) ? c.map(escape).join(" ") : escape(c));

Iterable<String> _filterCompletions(String partialWord, Iterable<String>
    completions) {
  return completions;
//  return partialWord == null ? completions : completions.where((c) => unescape(c
//      ).startsWith(partialWord));
}

String _COMPLETION = 'completion';

var _installationNames = _installationNamesHelp.keys;
// TODO: Replace this with an enum.
var _installationNamesHelp = {
  'print': 'Print completion script to stdout.',
  'install': 'Install completion script to .bashrc/.zshrc.',
  'uninstall': 'Uninstall completion script from .bashrc/.zshrc.'
};
