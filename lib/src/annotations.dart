
part of unscripted;

/// An annotation which marks named method parameters as command line options.
///
/// See the corresponding method parameters to [ArgParser.addOption]
/// for descriptions of the fields.
class Option extends HelpAnnotation {

  final String abbr;
  /// Either a `List<String>` of allowed values, or `Map<String, String>` of
  /// allowed values to help text.
  final allowed;
  final bool allowMultiple;
  /// Whether to hide this option.
  final bool hide;
  final defaultsTo;
  /// A function which validates and/or transforms the raw command-line String
  /// value into a form accepted by the [Script].  It should throw to indicate
  /// that the argument is invalid.
  final Function parser;
  /// A short label or description of the option's value.
  final String valueHelp;
  /// The non-abbreviated name used to identify the option on the command-line.
  final String name;

  const Option({
      help,
      parser(String arg),
      this.abbr,
      this.allowed,
      this.allowMultiple,
      this.hide,
      this.defaultsTo,
      this.valueHelp,
      this.name})
      : this.parser = parser,
        super(help: help);
}

/// An annotation which marks named method parameters as command line flags.
///
/// See the corresponding method parameters to [ArgParser.addFlag]
/// for descriptions of the fields.
class Flag extends Option {

  /// Whether this flag can be negated, e.g. with `--no-color` for a `--color`
  /// option.
  final bool negatable;

  const Flag({
      help,
      String abbr,
      defaultsTo,
      bool hide,
      bool negatable,
      String valueHelp,
      String name})
      : this.negatable = negatable == null ? false : negatable,
        super(help: help, abbr: abbr, defaultsTo: defaultsTo, hide: hide, valueHelp: valueHelp, name: name);
}

/// An annotation which gives example arguments that can be passed to a
/// [Command] or [SubCommand].
class ArgExample extends HelpAnnotation {

  /// The example arguments.
  ///
  /// Note:  This should not include the name of the command or sub-command
  /// itself, just the arguments.
  final String example;

  const ArgExample(this.example, {help}) : super(help: help);
}

/// An annotation which marks required positional parameters as
/// positional command line parameters.
class Positional extends HelpAnnotation {

  /// The name to identify the parameter with in usage text.  By
  /// default the name of the dart parameter is used converted from camelCase
  /// to dash-erized.
  final String valueHelp;

  /// A function which validates and/or transforms the raw command-line String
  /// value into a form accepted by the [Script].  It should throw to indicate
  /// that the argument is invalid.
  final Function parser;

  /// Either a `List<String>` of allowed values, or `Map<String, String>` of
  /// allowed values to help text.
  final allowed;

  const Positional({help, parser(String arg), this.valueHelp, this.allowed})
      : this.parser = parser,
      super(help: help);
}

/// An annotation which marks the last positional parameter of a method
/// as a rest argument.  If the parameter has a type annotation,
/// it should be `List` or `List<String>`.
class Rest extends Positional {

  /// Whether at least one rest argument is required.
  final bool required;

  const Rest({String valueHelp, help, parser(String arg), allowed, this.required: false})
      : super(valueHelp: valueHelp, parser: parser, help: help, allowed: allowed);
}

/// An annotation which marks a class as representing a script command.
class Command extends BaseCommand {
  /// The plugins to use with this command.
  final Iterable plugins;

  const Command({help, bool allowTrailingOptions: false, this.plugins})
      : super(help: help, allowTrailingOptions: allowTrailingOptions);
}

/// An annotation which marks an instance method of a [Command] as a
/// sub-command.
class SubCommand extends BaseCommand {

  /// Whether to hide this sub-command.
  final bool hide;

  /// [allowTrailingOptions] is inherited from the parent command by default.
  const SubCommand({help, bool allowTrailingOptions, this.hide})
      : super(help: help, allowTrailingOptions: allowTrailingOptions);
}
