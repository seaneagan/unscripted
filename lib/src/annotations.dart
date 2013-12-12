
part of unscripted;

/// A base class for script annotations which include help.
class _Help {
  final String help;

  const _Help({this.help});
}

/// A base class for script argument annotations.
class _Arg extends _Help {
  final String abbr;

  const _Arg({String help, this.abbr}) : super(help: help);
}

/// An annotation to use on named method parameters,
/// marking them as command line options.
///
/// See the corresponding method parameters to [ArgParser.addOption]
/// for descriptions of the fields.
class Option extends _Arg {
  final List<String> allowed;
  final Map<dynamic, String> allowedHelp;
  final bool allowMultiple;
  final bool hide;

  const Option({
      String help,
      String abbr,
      this.allowed,
      this.allowedHelp,
      this.allowMultiple,
      this.hide})
      : super(help: help, abbr: abbr);
}

/// An annotation to use on named method parameters,
/// marking them as command line flags.
///
/// See the corresponding method parameters to [ArgParser.addFlag]
/// for descriptions of the fields.
class Flag extends _Arg {
  final bool negatable;

  const Flag({
      String help,
      String abbr,
      this.negatable})
      : super(help: help, abbr: abbr);
}

/// An annotation which gives an example of arguments that can be passed to a
/// command, along with help text for the example.
class ArgExample extends _Help {

  final String example;

  const ArgExample(this.example, {String help}) : super(help: help);
}

/// An annotation for specifying metadata about positional command line
/// parameters.
class Positional extends _Help {

  final String name;

  const Positional({this.name, String help}) : super(help: help);
}

/// An annotation which marks the last positional parameter of a method
/// as a rest argument.  If the parameter has a type annotation,
/// it should be `List` or `List<String>`.
class Rest extends Positional {

  final int min;

  const Rest({this.min: 1, String name, String help})
      : super(name: name, help: help);
}

class _BaseCommand extends _Help {
  const _BaseCommand({String help}) : super(help: help);
}

/// An annotation which marks a class as representing a script command.
class Command extends _BaseCommand {
  final CallStyle callStyle;

  const Command({String help, this.callStyle}) : super(help: help);
}

/// An annotation which can be used on a class to mark it as representing a
/// script command.
class SubCommand extends _BaseCommand {
  const SubCommand({String help}) : super(help: help);
}
