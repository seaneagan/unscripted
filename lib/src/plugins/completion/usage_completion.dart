
library unscripted.plugins.completion.usage_completion;

import 'dart:async';

import '../../../unscripted.dart';
import '../../usage.dart';

import 'command_line.dart';

Future<Iterable> getUsageCompletions(Usage usage, CommandLine commandLine) => new Future.sync(() {

  // Only support completions at the end of lines for now.
  // TODO: Relax this to support the cursor being in the last non-empty word.
  if(commandLine.cursor != commandLine.line.length) return [];

  // Try to find a valid subset of the args.
  CommandInvocation commandInvocation;
  var validWords = commandLine.partialWords.toList();
  while(validWords.isNotEmpty) {
    validWords.removeLast();
    try {
      commandInvocation = usage.parse(validWords);
      break;
    } on UsageException {
      // TODO: Log?
    }
  }

  var toComplete = commandLine.word;

  if(commandInvocation == null) {
    // TODO: How to recover here?
    return [];
  }

  // Find leaf command and usage.
  var leafCommandInvocation = commandInvocation;
  var leafUsage = usage;
  // Aggregate allowed and provided options.
  var allowedOptions = new Map.from(leafUsage.options);
  while(leafCommandInvocation.subCommand != null) {
    leafCommandInvocation = leafCommandInvocation.subCommand;
    leafUsage = usage.commands[leafCommandInvocation.name];
    allowedOptions.addAll(leafUsage.options);
  }

  // TODO: Remove options that have already been provided on the command line,
  // and don't have allowMultiple true.  Take allowTrailingOptions and '--'
  // argument into account.
  var completionOptions = new Map<String, Option>.from(allowedOptions);

  // User is trying to specify an option.
  if(toComplete.startsWith('-')) {

    if(commandLine.word.startsWith('--')) {
      // Long option
      var prefix = commandLine.word.substring(2);
      return completionOptions.keys
          .where((option) => option.startsWith(prefix))
          .map((option) => "--$option");
    } else {
      // Short option
      var abbrs = toComplete.substring(1).split('');
      if(abbrs.isEmpty) {
        // Complete option.
        return completionOptions.keys.map((option) => "--$option");
      }
      String findByAbbr(String abbr) {
        return completionOptions.keys.firstWhere((option) => completionOptions[option].abbr == abbr, orElse: () => null);
      }
      var options = abbrs.map(findByAbbr);
      var allAbbrsFound = options.every((option) => option != null);
      var singleOption = options.length == 1;
      var allFlags = options.every((option) => completionOptions[option] is Flag);
      if(allAbbrsFound && (singleOption || allFlags)) {
        return [options.map((option) => '--$option')];
      }
      return [];
    }
  } else {

    if(commandLine.partialWords.length >= 2) {
      var previousWord = commandLine.partialWords.elementAt(
          commandLine.partialWords.length - 2);
      if(previousWord.startsWith('-')) {
        // Maybe completing an option value.

        if(previousWord.startsWith('--')) {
          // Long option
          var opt = previousWord.substring(2);
          if(completionOptions.containsKey(opt)) {
            var option = completionOptions[opt];
            return _getCompletionsForOption(option, toComplete);
          }
        } else {
          // Short option
          if(previousWord.length == 2) {
            var abbr = previousWord[1];
            var option = completionOptions.values.singleWhere((option) => option.abbr == abbr);
            return _getCompletionsForOption(option, toComplete);
          }
        }
      }
    }

    // Try completing command.
    var commandCompletions = leafUsage.commands.keys.where((command) =>
        command.startsWith(toComplete));
    if(commandCompletions.isNotEmpty) return commandCompletions;

    // Try completing positional.
    var positional = leafUsage.positionalAt(leafCommandInvocation.positionals.length);
    if(positional != null) {
      if(positional.allowed != null) {
        return _getCompletionsForAllowed(positional.allowed, toComplete);
      }
    }
  }

  // If empty, assume they want an option.
  if(toComplete.isEmpty) return completionOptions.keys.map((option) => "--$option");

  // Give up.
  return [];
});

Future<Iterable<String>> _getCompletionsForOption(Option option, String prefix) => new Future.sync(() {
  // Flags don't have value arguments.
  if(option is Flag) {
    return [];
  }
  return _getCompletionsForAllowed(option.allowed, prefix);
});

Future<Iterable<String>> _getCompletionsForAllowed(allowed, String prefix) {
  if(allowed is _CompleteText) return new Future.sync(() => allowed(prefix));
  return new Future.sync(() {
    if(allowed is Iterable) return allowed;
    else if(allowed is _Complete) return allowed();
    else if(allowed is Map) return allowed.keys;
    return [];
  }).then((completions) => completions.where((v) => v.startsWith(prefix)));
}

typedef _CompleteText(String prefix);
typedef _Complete();
