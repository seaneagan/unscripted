
part of unscripted.completion;

Iterable getUsageCompletions(Usage usage, CommandLine commandLine) {

  // Only support completions at the end of lines for now.
  // TODO: Relax this to support the cursor being in the last non-empty word.
  if(commandLine.cursor != commandLine.line.length) return [];

  // Try to find a valid subset of the args.
  CommandInvocation commandInvocation;
  var validWords = commandLine.partialWords.toList();
  while(validWords.isNotEmpty) {
    validWords.removeLast();
    try {
      commandInvocation = usage.validate(validWords);
      break;
    } on UsageException catch (e, s) {
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

  if(!toComplete.startsWith('-')) {
    // Try completing command.
    // TODO: Could be a positional arg as well.
    var commandUsage = usage;
    var completedWords = commandLine.partialWords.toList()..removeLast();
    completedWords.every((word) =>
        (commandUsage = commandUsage.commands[word]) != null);
    if(commandUsage != null) {
      return commandUsage.commands.keys.where((command) => command.startsWith(toComplete));
    }
  }

  // TODO: Remove options that have already been provided on the command line,
  // and don't have allowMultiple true.  Take allowTrailingOptions and '--'
  // argument into account.
  var completionOptions = new Map<String, Option>.from(allowedOptions);
  Iterable<String> completions = [];

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
        return ['--', '--this-should-never-be-seen'];
        // TODO: Return short options like below instead?
      }
      if(abbrs.length == 1) {
        var abbr = abbrs.single;
        var opt = completionOptions.keys.firstWhere((opt) {
          var option = completionOptions[opt];
          // TODO: Bail out on non-flags here?
          return option.abbr == abbr;
        }, orElse: () => null);
        if(opt != null) return ['--$opt'];
      }
      return [];
    }
  }

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

  return completions;
}

Iterable<String> _getCompletionsForOption(Option option, String prefix) {
  // The word must be a command or positional argument.
  if(option is Flag) {
    return [];
  }

  var allowed = option.allowed;
  var newAllowed = allowed;
  if(allowed is Iterable) newAllowed = allowed;
  else if(allowed is _CompletionFilter) newAllowed = allowed(prefix);
  else if(allowed is Map) newAllowed = allowed.keys;
  if(newAllowed != null) {
    return newAllowed.where((v) => v.startsWith(prefix));
  }
  return [];
}

// TODO: Allow returning a Future<Iterable<String>>
typedef Iterable<String> _CompletionFilter(String prefix);
