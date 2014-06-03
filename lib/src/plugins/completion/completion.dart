
library unscripted.completion;

import 'dart:io';
import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:unscripted/src/usage.dart';
import 'package:unscripted/unscripted.dart';

part 'usage_completion.dart';
part 'command_line.dart';
part 'completion_script.dart';

Future complete (
    Usage usage,
    CommandInvocation completionCommand,
    {bool isWindows,
     Map<String, String> environment}) => new Future.sync(() {

  if (isWindows) {
    var ENOTSUP = 252;
    exitCode = ENOTSUP;
    throw new UnsupportedError(
        "${formatCallStyle(usage.callStyle)} completion not supported on windows");
  }

  if(environment == null) environment = Platform.environment;
  var args = completionCommand.positionals.single;
  var commandLine = new CommandLine(args, environment: environment);
  if(commandLine == null) {
    var completionSubCommand = completionCommand.subCommand;
    var commandToComplete = formatCallStyle(usage.callStyle);
    if(completionSubCommand == null) {
      print(getScriptOutput(commandToComplete));
    } else {
      var subCommandName = completionSubCommand.name;
      switch(subCommandName) {
        case 'install': installScript(commandToComplete); break;
        case 'uninstall': uninstallScript(commandToComplete); break;
        default: throw 'Unrecognized completion sub-command';
      }
    }
  } else {
    // "Plumbing mode"
    var result = getCompletionOutput(usage, commandLine);

    getCompletionOutput(usage, commandLine).then((String output) {
      if(output.isNotEmpty) {
        print(output);
      }
    });
  }
});

Future<String> getCompletionOutput(Usage usage, CommandLine commandLine) {
  return getUsageCompletions(usage, commandLine).then((completions) {
    completions = filterCompletions(
      commandLine.partialWord, expandCompletions(completions));

    return completions.join('\n');
  });
}

Iterable<String> expandCompletions(Iterable completions) =>
  completions.map((c) => (c is Iterable) ?
      c.map(escape).join(" ") :
      escape(c));

Iterable<String> filterCompletions(String partialWord, Iterable<String> completions) {
  return partialWord == null ? completions : completions.where((c) =>
    unescape(c).startsWith(partialWord));
}

String unescape(String w) {
  if (w.startsWith('"')) return w.replaceAll(new RegExp(r'^"|"$'), "");
  return w.replaceAll(new RegExp(r'\\ '), " ");
}

String escape(String w) {
  if (!new RegExp(r'\s+').hasMatch(w)) return w;
  return '"$w"';
}

addCompletionCommand(Usage usage) {
  var completionCommand = usage.addCommand('completion')
      ..description =
          'Install, uninstall, or output a bash/zsh completion script for use with this command'
      ..rest = new Rest(help:
          'These are used only by the completion script', name: 'args')
      ..addExample(new ArgExample('install'))
      ..addExample(new ArgExample('uninstall'))
      ..addExample(new ArgExample('>> /usr/local/etc/bash_completion.d/${formatCallStyle(usage.callStyle)}'));
  completionCommand.addCommand('install')
      ..description = 'Install completion script in shell startup script (.bashrc/.zshrc)';
  completionCommand.addCommand('uninstall')
      ..description = 'Uninstall completion script from shell startup script (.bashrc/.zshrc)';
}

// final shells = ['bash', 'zsh'];
String shellConfig(shell) => '.${shell}rc';
