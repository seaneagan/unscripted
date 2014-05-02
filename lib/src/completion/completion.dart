
library unscripted.completion;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unscripted/src/usage.dart';
import 'package:unscripted/unscripted.dart';

part 'usage_completion.dart';
part 'command_line.dart';
part 'completion_script.dart';

//completion.usage = "npm completion >> ~/.bashrc\n"
//                 + "npm completion >> ~/.zshrc\n"
//                 + "source <(npm completion)"

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
        "${usage.name} completion not supported on windows");
  }

  if(environment == null) environment = Platform.environment;
  var commandLine = new CommandLine(args, environment: environment);
  var output = commandLine == null ?
    getScriptOutput(usage.name) :
    // "Plumbing mode"
    getCompletionOutput(usage, commandLine);

  print(output);
}

String getCompletionOutput(Usage usage, CommandLine commandLine) {

  var completions = (commandLine.wordIndex > 3) ?
    getUsageCompletions(usage, commandLine) :
    getCompletionCommandCompletions(commandLine);

    completions = filterCompletions(
      commandLine.partialWord, expandCompletions(completions));

  return completions.join('\n');
}

// TODO: Replace with `install` and `uninstall` sub-commands.
Iterable getCompletionCommandCompletions(CommandLine commandLine) {
  shellConfig(shell) => '.${shell}rc';
  bool shellConfigExists(String shellConfig) => new File(
      path.join(Platform.environment['HOME'], shellConfig)).existsSync();
  var completions = ['bash', 'zsh']
      .map(shellConfig).where(shellConfigExists)
      .map((config) => path.join('~', config));
  if (commandLine.wordIndex == 2) {
    completions = completions.map((configPath) => [">>", configPath]);
  }
  return completions;
}

Iterable<String> expandCompletions(Iterable completions) =>
  completions.map((c) => (c is Iterable) ?
      c.map(escape).join(" ") :
      escape(c));

Iterable<String> filterCompletions(String partialWord, Iterable<String> completions) {
  return partialWord == null ? completions : completions.where((c) =>
    unescape(c).startsWith(partialWord));
}

String completionsOutput(Iterable<String> completions) => (completions.join("\n"));

String unescape (String w) {
  if (w.startsWith('"')) return w.replaceAll(new RegExp(r'^"|"$'), "");
  return w.replaceAll(new RegExp(r'\\ '), " ");
}

String escape (String w) {
  if (!new RegExp(r'\s+').hasMatch(w)) return w;
  return '"$w"';
}
