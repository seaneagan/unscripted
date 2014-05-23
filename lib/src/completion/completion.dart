
library unscripted.completion;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unscripted/src/usage.dart';
import 'package:unscripted/unscripted.dart';

part 'usage_completion.dart';
part 'command_line.dart';
part 'completion_script.dart';

void complete (
    Usage usage,
    List<String> args,
    {bool isWindows,
     Map<String, String> environment}) {

  if(isWindows == null) isWindows = Platform.isWindows;
  if (isWindows) {
    var ENOTSUP = 252;
    exitCode = ENOTSUP;
    throw new UnsupportedError(
        "${formatCallStyle(usage.callStyle)} completion not supported on windows");
  }

  if(environment == null) environment = Platform.environment;
  var commandLine = new CommandLine(args, environment: environment);
  var output = commandLine == null ?
    getScriptOutput(formatCallStyle(usage.callStyle)) :
    // "Plumbing mode"
    getCompletionOutput(usage, commandLine);

  if(output.isNotEmpty) print(output);
}

String getCompletionOutput(Usage usage, CommandLine commandLine) {

  var completions = getUsageCompletions(usage, commandLine);

  completions = filterCompletions(
    commandLine.partialWord, expandCompletions(completions));

  return completions.join('\n');
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
  var completionUsage = usage.addCommand('completion');
  // TODO: How to add `. <(foo completion)` example?
  shellConfigs.map((config) => new ArgExample('>> ${tildePath(config)}'))
      .forEach(completionUsage.addExample);
  completionUsage.description =
      'Outputs a bash/zsh completion script for use with this command';
  completionUsage.rest = new Rest(help: 'These are used only by the completion script', name: 'args');
}

final shells = ['bash', 'zsh'];
final shellConfigs = shells.map(shellConfig);
String shellConfig(shell) => '.${shell}rc';
String tildePath(String subPath) => path.join('~', subPath);
