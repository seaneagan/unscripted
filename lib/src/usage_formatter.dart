
part of unscripted.usage;

abstract class UsageFormatter {

  final Usage usage;

  String format();

  UsageFormatter(this.usage);
}

AnsiPen get titlePen {
	return new AnsiPen()..white(bold: true);
}

// TODO: Add tests for this.
class TerminalUsageFormatter extends UsageFormatter {

  TerminalUsageFormatter(Usage usage) : super(usage);

  String format() {

    var oldColorDisabled = color_disabled;

    color_disabled = shouldDisableColor();

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
          usage.examples.map((example) => _formatExample(example))
              .join('\n')]);
    }

    var usageParts = [_formatCommands()];

    var optionsPlaceholder = '[options]';
    var args = parser.commands.isEmpty ? optionsPlaceholder : 'command';
    usageParts.add(args);

    var positionalNames = usage.positionals.map((positional) => positional.name);
    usageParts.addAll(positionalNames);

    var restName = usage.rest == null ? '' : usage.rest.name;

    if(restName != null && restName.isNotEmpty) {
      if(!usage.rest.required) restName = '[$restName]';
      restName = '$restName...';
      usageParts.add(restName);
    }

    if(parser.commands.isNotEmpty) {
      blocks.add(['Available commands', '''
${parser.commands.keys.join('\n')}

Use "${_formatRootCommand()} $HELP [command]" for more information about a command.''']);
    }

    var usageString = usageParts.join(' ');

    blocks.insert(0, ['Usage', usageString]);

    var blockStrings = blocks
        .map((block) => _formatBlock(block[0], block[1]))
        .toList();

    if(description.isNotEmpty) blockStrings.insert(0, description);

    color_disabled = oldColorDisabled;

    return blockStrings.join('\n\n') + '\n';
  }

  _formatExample(ArgExample example) {
    var parts = [_formatCommands(), example.example];
    if(example.help != null && example.help.isNotEmpty) {
      parts..add('#')..add(example.help);
    }
    return parts.join(' ');
  }

  String _formatRootCommand() => formatCallStyle(usage.callStyle);

  String _formatCommands() =>
      ([_formatRootCommand()]..addAll(usage.commandPath)).join(' ');

  String _formatBlock(String title, String content) {
    return '''
${titlePen(title)}:

${indentLines(content)}''';
  }
}

formatCallStyle(CallStyle callStyle) {
  var commandName = path.basenameWithoutExtension(path.fromUri(Platform.script));
  switch(callStyle) {
    case CallStyle.NORMAL: return 'dart $commandName.dart';
    case CallStyle.SHEBANG: return '$commandName.dart';
    case CallStyle.SHELL: return commandName;
  }
}

indentLines(String text) =>
    const LineSplitter().convert(text).map((line) => indentLine(line, 2)).join('\n');

indentLine(String line, int spaces, {int depth: 1}) => '${repeat(' ', spaces * depth)}$line';

// TODO: May need to also disable when testing help formatting output.
bool shouldDisableColor() => Platform.operatingSystem == 'windows' ||
      !stdout.hasTerminal;
