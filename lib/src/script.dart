
part of unscripted;

/// Derives and returns a [Script] from [model].
///
/// The model is just an ordinary programming construct, particularly either a
/// closure ([Function]) or class ([Type]), annotated with command line
/// interface metadata.  The model itself can be annotated as a [Command].  The
/// returned script automatically includes adds '--help' / '-h' flags, and
/// prints help information when these flags are passed, or when the script was
/// invoked incorrectly.
///
/// For simple scripts without sub-commands, the model should be a [Function].
/// The function's parameters define the command line parameters
/// accepted by the script.  Named parameters with [bool] type annotations or
/// [Flag] metadata annotations are considered flags.  Named parameters with a
/// [String] or [dynamic] type annotations or [Option] metadata annotations are
/// considered options.  Required positional parameters are mapped to
/// positional command line parameters.  Optional positional parameters are not
/// allowed.  However, a [Rest] metadata annotation can be placed on the last
/// positional parameter to represent all remaining positional arguments past
/// to the script.
///
/// When the returned script is [executed][Script.execute], the command line
/// arguments are injected into their corresponding function arguments.
///
///     main(arguments) => improvise(greet).execute(arguments);
///
///     @Command(help: 'Outputs a greeting')
///     @ArgExample('--exclaim --salutation Howdy Mr. John Doe', help: 'enthusiastic')
///     greet(
///         @Positional(help: "such as 'Mr.' or 'Mrs.'")
///         String title,
///         @Rest(help: "One or more names to greet, e.g. 'Jack' or 'Jack Jill'")
///         List<String> who,
///         {String salutation : 'Hello',
///          bool exclaim : false}) {
///
///       print('$salutation $title ${who.join(' ')}${exclaim ? '!' : ''}');
///
///     }
///
/// For scripts with sub-commands, the model should be a class ([Type]), which
/// must have an unnamed constructor, whose parameters define the
/// top-level options for this script.  Methods of the class can be annotated
/// as [SubCommand]s.  These methods define and implement the sub-commands
/// of the script.  A 'help' sub-command is also added which can be invoked bare
/// or with the name of a sub-command for which to print help.
///
/// When the returned script is [executed][Script.execute], the base command line
/// arguments (before the command) are injected into their corresponding
/// constructor arguments, to create an instance of the class.  Then, the method
/// corresponding to the sub-command and associated arguments that were
/// specified on the command line are used to invoke the corresponding method
/// on the instance which will have access to any global options through
/// instance variables that were set in the constructor.
///
///     main(arguments) => improvise(Commands).execute(arguments);
///
///     @Command(help: 'Does command-ish stuff')
///     class Commands {
///
///       @SubCommand(help: 'Does foo')
///       @ArgExample('--foo-flag')
///       foo({bool fooFlag}) {
///         print('foo');
///         print('fooFlag: $fooFlag');
///       }
///
///       @SubCommand()
///       bar() {
///         print('bar');
///       }
///
///       @SubCommand()
///       baz(@Rest(help: '<items>') items) {
///         print(items.join(', '));
///         print('baz');
///       }
///     }
///
/// Parameter and command names which are camelCased are mapped to their
/// dash-erized command line equivalents.  For example, `fooBar` would map to
/// `foo-bar`.
Script improvise(model) {
  if(model is Function) return new FunctionScript(model);
  if(model is Type) return new ClassScript(model);
  throw new ArgumentError('model must be a Type or Function');
}

/// Represents a command line script.
///
/// The main way to interact with a [Script] is to [execute] it.
///
///
///
abstract class Script {

  Usage get usage;

  UsageFormatter getUsageFormatter(Usage usage) =>
      new TerminalUsageFormatter(usage);

  /// Executes this script.
  ///
  /// * Parses the [arguments].
  /// * Outputs help info and exits if:
  ///   * The arguments were invalid
  ///   * Help was requested via any of:
  ///     * `foo.dart --help`
  ///     * `foo.dart -h`
  ///     * `foo.dart help`
  ///     * `foo.dart command --help`
  ///     * `foo.dart help command`
  /// * Otherwise, passes the [ArgResults] to [handleResults].
  execute(List<String> arguments) {

    ArgResults results;

    try {
      results = usage.validate(arguments);
    } catch(e) {
      print('$e\n');
      printHelp();
      return;
    }

    if(_checkHelp(results)) return;
    handleResults(results);

  }

  /// Handles successfully parsed [results].
  handleResults(ArgResults results);

  /// Prints help information for the associated command or sub-command thereof
  /// at [commandPath].
  // TODO: Integrate with Loggers.
  printHelp([List<String> commandPath]) {
    var helpUsage = (commandPath == null ? [] : commandPath)
        .fold(usage, (usage, subCommand) =>
            usage.commands[subCommand]);
    print(getUsageFormatter(helpUsage).format());
  }

  bool _checkHelp(ArgResults results) {
    var path = getHelpPath(results);
    if(path != null) {
      printHelp(path);
      return true;
    }
    return false;
  }
}
