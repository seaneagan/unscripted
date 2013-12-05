
part of ink;

abstract class UsageFormat {
  String format(Usage usage);
}

// TODO: Add tests for this.
class TerminalUsageFormat extends UsageFormat {
  String format(Usage usage) {

    var parser = usage.parser;
    var description = usage.description;
    if(description == null) description = '';

    var blocks = [];

    var hasOptions = parser.options.isNotEmpty;

    if(hasOptions) {
      blocks.add(['Options', parser.getUsage()]);
    }

    if(usage.examples.isNotEmpty) {
      blocks.add([
          'Examples',
          usage.examples.map((example) => _formatExample(usage, example))
              .join('\n')]);
    }

    var usageParts = [_formatCommands(usage)];

    var optionsPlaceholder = '[options]';
    var args = parser.commands.isEmpty ? optionsPlaceholder : 'command';
    usageParts.add(args);

    var restHelp = usage.rest == null ? '' : usage.rest.help;
    if(restHelp != null && restHelp.isNotEmpty) usageParts.add(restHelp);

    if(parser.commands.isNotEmpty) {
      blocks.add(['Available commands', '''
${parser.commands.keys.map((command) => '  $command\n').join()}
Use "rootCommand $_HELP [command]" for more information about a command.''']);
    }

    var usageString = usageParts.join(' ');

    blocks.insert(0, ['Usage', usageString]);

    var blockStrings = blocks
        .map((block) => _formatBlock(block[0], block[1]))
        .toList();

    if(description.isNotEmpty) blockStrings.insert(0, description);

    return blockStrings.join('\n\n');
  }

  _formatExample(Usage usage, ArgExample example) {
    var parts = [_formatCommands(usage), example.example];
    if(example.help != null && example.help.isNotEmpty) {
      parts..add('#')..add(example.help);
    }
    return parts.join(' ');
  }

  String _formatRootCommand(Usage usage) {
    var commandName = basenameWithoutExtension(Platform.script.path);
    return usage.callStyle.formatCommand(commandName);
  }

  String _formatCommands(Usage usage) =>
      ([_formatRootCommand(usage)]..addAll(usage.commandPath)).join(' ');

  String _formatBlock(String title, String content) {
    return '''
$title:

$content''';
  }
}
