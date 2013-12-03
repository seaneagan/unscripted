
part of ink;

abstract class UsageFormat {
  String format(Usage usage);
}

class TerminalUsageFormat extends UsageFormat {
  String format(Usage usage) {

    var parser = usage.parser;
    var description = usage.description;
    var path = usage.commandPath;

    if(path == null) path = const [];
    if(description == null) description = '';
    var descriptionBlock = description.isEmpty ? '' : '''
$description
''';

    var optionsPlaceholder = '[options]';
    var scriptName = basename(Platform.script.path);
    var hasOptions = parser.options.isEmpty;
    var globalOptions = hasOptions ? '' : ' $optionsPlaceholder';
    var optionsBlock = hasOptions ? '' : '''

Options:

${parser.getUsage()}''';

    var commandBlock = '';
    var commandPlaceholder = '';
    if(path.isNotEmpty) {
      globalOptions = '';
      commandPlaceholder = ' ${path.join(' ')} $optionsPlaceholder';
    } else if(parser.commands.isNotEmpty) {
      globalOptions = '';
      commandPlaceholder = ' command';
      commandBlock = '''

Available commands:

${parser.commands.keys.map((command) => '  $command\n').join()}
Use "$scriptName $_HELP [command]" for more information about a command.''';
    }

    return '''
$descriptionBlock
Usage: $scriptName$globalOptions$commandPlaceholder
$optionsBlock
$commandBlock
''';
  }
}
