
part of unscripted;

/// An annotation which marks named method parameters as command line options.
///
/// See the corresponding method parameters to [ArgParser.addOption]
/// for descriptions of the fields.
class Option extends Arg {
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

/// An annotation which marks named method parameters as command line flags.
///
/// See the corresponding method parameters to [ArgParser.addFlag]
/// for descriptions of the fields.
class Flag extends Arg {
  final bool negatable;

  const Flag({
      String help,
      String abbr,
      this.negatable})
      : super(help: help, abbr: abbr);
}

/// An annotation which gives example arguments that can be passed to a
/// [Command] or [SubCommand].
class ArgExample extends Help {

  /// The example arguments.
  ///
  /// Note:  This should not include the name of the command or sub-command
  /// itself, just the arguments.
  final String example;

  const ArgExample(this.example, {String help}) : super(help: help);
}

/// An annotation which marks required positional parameters as
/// positional command line parameters.
class Positional extends Help {

  /// The name with which to identify the parameter to in usage text.  By
  /// default the name of the dart parameter is used converted from camelCase
  /// to dash-erized.
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

/// An annotation which marks a class as representing a script command.
class Command extends BaseCommand {
  final CallStyle callStyle;

  const Command({String help, this.callStyle}) : super(help: help);
}

/// An annotation which marks an instance method of a [Command] as a
/// sub-command.
class SubCommand extends BaseCommand {
  const SubCommand({String help}) : super(help: help);
}
