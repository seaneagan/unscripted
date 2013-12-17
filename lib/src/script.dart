
part of unscripted;

/// "Sketches" a [Script] from [model].
///
/// The model is either a closure ([Function]) or class ([Type]), annotated
/// with command-line specific metadata.  The model itself can be annotated as
/// a [Command].  The returned script automatically includes '--help' / '-h'
/// flags, and prints help information when these flags are passed, or when the
/// script was invoked incorrectly.
///
/// For scripts without sub-commands, the model should be a [Function].
/// The function's parameters define the script's command-line parameters.
/// Named parameters with [bool] type annotations or [Flag] metadata annotations
/// are considered flags.  Named parameters with [String] or [dynamic] type
/// annotations or [Option] metadata annotations are considered options.
/// Required positional parameters are mapped to positional command-line
/// parameters.  Optional positional parameters are not allowed.  However, a
/// [Rest] metadata annotation can be placed on the last positional parameter
/// to represent all remaining positional arguments passed to the script.
///
/// When the returned script is [executed][Script.execute], the command-line
/// arguments are injected into their corresponding function arguments.
///
///     main(arguments) => sketch(greet).execute(arguments);
///
///     // Optional command-line metadata:
///     @Command(help: 'Outputs a greeting')
///     @ArgExample('--salutation Welcome --exclaim Bob', help: 'enthusiastic')
///     greet(
///         @Rest(help: "Name(s) to greet")
///         List<String> who, // A rest parameter, must be last positional.
///         {String salutation : 'Hello', // An option, use `@Option(...)` for metadata.
///          bool exclaim : false}) { // A flag, use `@Flag(...)` for metadata.
///
///       print('$salutation ${who.join(' ')}${exclaim ? '!' : ''}');
///
///     }
///
/// For scripts with sub-commands, the model must be a class ([Type]), which
/// must have an unnamed constructor, whose parameters define the
/// top-level options for the script.  Methods of the class can be annotated
/// as [SubCommand]s.  These methods define and implement the sub-commands
/// of the script.  A 'help' sub-command is also added which can be invoked bare
/// or with the name of a sub-command for which to print help.
///
/// When the returned script is [executed][Script.execute], the global command
/// line arguments are injected into their corresponding constructor arguments
/// to create an instance of the class.  Then, the method corresponding to the
/// sub-command and associated arguments that were specified on the command-line
/// are used to invoke the corresponding method on the instance which will have
/// access to any global options through instance variables that were set in
/// the constructor.
///
///     main(arguments) => sketch(Server).execute(arguments);
///
///     @Command(help: 'Manages a server')
///     class Server {
///
///       final String configPath;
///
///       Server({this.configPath: 'config.xml'});
///
///       @SubCommand(help: 'Start the server')
///       start({bool clean}) {
///         print('''
///     Starting the server.
///     Config path: $configPath''');
///       }
///
///       @SubCommand(help: 'Stop the server')
///       stop() {
///         print('Stopping the server.');
///       }
///
///     }
///
/// Commands and SubCommands can also be annotated with [ArgExample]s, to
/// document in the help text example arguments that they can receive.
///
/// Parameter and command names which are camelCased are mapped to their
/// dash-erized command-line equivalents.  For example, `fooBar` would map to
/// `foo-bar`.
Script sketch(model) {
  if(model is Function) return new FunctionScript(model);
  if(model is Type) return new ClassScript(model);
  throw new ArgumentError('model must be a Type or Function');
}

/// Represents a command-line script.
///
/// The main way to interact with a script is to [execute] it.
abstract class Script {

  /// Executes this script.
  ///
  /// First, the [arguments] are parsed.  If the arguments were invalid *or*
  /// if help was requested, help text is printed and the method returns.
  /// Otherwise, script-specific logic is executed on the successfully parsed
  /// arguments.
  execute(List<String> arguments);

}
