
part of unscripted.plugins.help;

abstract class UsageFormatter {

  final Usage usage;

  String format();

  UsageFormatter(this.usage);
}

// TODO: Add tests for this.
class TerminalUsageFormatter extends UsageFormatter {

  final bool color;

  TerminalUsageFormatter(Usage usage, this.color) : super(usage);

  String format() {

    var oldColorDisabled = color_disabled;

    color_disabled = !color;

    var parser = usage.parser;
    var description = getHelp(usage.description);
    if(description == null) description = '';

    var blocks = [];

    var hasOptions = parser.options.isNotEmpty;

    if(hasOptions) {
      var optionHelp = new OptionHelp(usage).generate();
      blocks.add(['Options', optionHelp]);
    }

    if(usage.examples.isNotEmpty) {
      blocks.add([
          'Examples',
          formatColumns(
              usage.examples.map((ArgExample example) {
                var help = getHelp(example.help);
                return [_getCommandString(), example.example, help == null ? '' : '# $help'];
              }),
              [namePen, null, textPen], separateBy: 1)]);
    }

    var usageParts = [_formatCommands()];

    var optionsPlaceholder = optionPen('[options]');
    var commandPlaceholder = '${commandPen('<command>')} ${textPen('[<args>]')}';
    usageParts.add(optionsPlaceholder);
    if(usage.commands.isNotEmpty) usageParts.add(commandPlaceholder);

    var positionalNames = usage.positionals.map((positional) => positionalPen('<${positional.valueHelp}>'));
    usageParts.addAll(positionalNames);

    var restName = usage.rest == null ? '' : usage.rest.valueHelp;

    if(restName != null && restName.isNotEmpty) {
      restName = '<$restName>...';
      if(!usage.rest.required) restName = '[$restName]';
      usageParts.add(positionalPen(restName));
    }

    var visibleCommands = mapWhere(usage.commands, (key, value) => !value.hide);
    if(visibleCommands.isNotEmpty) {
      blocks.add(['Commands', '''
${formatColumns(
    visibleCommands.keys.map((command) => [command, ((s) => s == null ? '' : s)(getHelp(visibleCommands[command].description))]),
    [commandPen, textPen])}

${textPen("See '")}${_formatCommands()} $_HELP ${commandPen('[command]')}${textPen("' for more information about a command.")}''']);
    }

    var usageString = usageParts.join(' ');

    var positionalsWithRest = usage.positionals;
    if(usage.rest != null) positionalsWithRest = positionalsWithRest.toList()..add(usage.rest);
    positionalsWithRest = positionalsWithRest.where((positional) => positional.help != null);
    if(positionalsWithRest.isNotEmpty) {
      usageString = '''
$usageString

${indentLines(formatColumns(
    positionalsWithRest.map((positional) => ['<${positional.valueHelp}>', getHelp(positional.help)]),
    [positionalPen, textPen]))}''';
    }

    blocks.insert(0, ['Usage', usageString]);

    if(description.isNotEmpty) blocks.insert(0, ['Description', textPen(description)]);

    var blockStrings = blocks
        .map((block) => _formatBlock(block[0], block[1]))
        .toList();

    color_disabled = oldColorDisabled;

    return '\n' + blockStrings.join('\n\n') + '\n';
  }

  String _formatCommands() =>
      namePen(_getCommandString());

  String _getCommandString() =>
      ([formatCallStyle(usage.callStyle)]..addAll(usage.commandPath)).join(' ');

  String _formatBlock(String title, String content) {
    return '''
${titlePen(title)}:

${indentLines(content)}''';
  }
}

indentLines(String text) =>
    const LineSplitter().convert(text).map((line) => indentLine(line, 2)).join('\n');

indentLine(String line, int spaces, {int depth: 1}) => '${' ' * (spaces * depth)}$line';
