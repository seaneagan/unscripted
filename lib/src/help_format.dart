
part of ink;

class HelpFormat {
  format(Script script) {

  }
}

class CommandHelp {
  final String description;
  final Map<String, CommandHelp> commands;
  final Map<String, Option> options;
  final Rest rest;
  final List<String> argExamples;
  final CallStyle
  final List<String> subCommandPath;
  final String name;
  final CommandHelp parent;
}
