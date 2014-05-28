
part of unscripted.completion;

String getMarker(String command, String type) => '###-$type-$command-completion-###';
String getBeginMarker(String command) => '\n' + getMarker(command, 'begin');
String getEndMarker(String command) => getMarker(command, 'end') + '\n';

String getScriptOutput (String command) {

  var completionCommand = '$command completion';
  var func = '_${command.replaceAll(new RegExp(r'[.-]'), '_')}_completion';

  return '''
${getBeginMarker(command)}
#
# $command command completion script
#
# Installation: $completionCommand >> ~/.bashrc  (or ~/.zshrc)
# Or, maybe: $completionCommand > /usr/local/etc/bash_completion.d/$command
#

COMP_WORDBREAKS=\${COMP_WORDBREAKS/=/}
COMP_WORDBREAKS=\${COMP_WORDBREAKS/@/}
export COMP_WORDBREAKS

if type complete &>/dev/null; then
  $func () {
    local si="\$IFS"
    IFS=\$'\n' COMPREPLY=(\$(export COMP_CWORD="\$COMP_CWORD" \
                           export COMP_LINE="\$COMP_LINE" \
                           export COMP_POINT="\$COMP_POINT" \
                           $completionCommand -- "\${COMP_WORDS[@]}" \
                           2>/dev/null)) || return \$?
    IFS="\$si"
  }
  complete -F $func $command
elif type compdef &>/dev/null; then
  $func() {
    si=\$IFS
    compadd -- \$(export COMP_CWORD=\$((CURRENT-1)) \
                 export COMP_LINE=\$BUFFER \
                 export COMP_POINT=0 \
                 $completionCommand -- "\${words[@]}" \
                 2>/dev/null)
    IFS=\$si
  }
  compdef $func $command
elif type compctl &>/dev/null; then
  $func () {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="\$IFS"
    IFS=\$'\n' reply=(\$(export COMP_CWORD="\$cword" \
                       export COMP_LINE="\$line" \
                       export COMP_POINT="\$point" \
                       $completionCommand -- "\${words[@]}" \
                       2>/dev/null)) || return \$?
    IFS="\$si"
  }
  compctl -K $func $command
fi
${getEndMarker(command)}''';
}

installScript(String command) {
  var installCommand = '$command completion install';
  print('Installing completion for $command');

  var rcText = readRc(command);
  if(rcText == null) {
    var fileName = path.basename(shellRc.path);
    throw "No $fileName file. You'll have to instead run: $command completion >> ~/$fileName";
  }

  var parts = rcText.split(getBeginMarker(command));
  if(parts.length >= 2) {
    print(' ✗ $command completion was already installed. Nothing to do.');
    return;
  }

  appendRc(command, getScriptOutput(command));
  print('''
 ✓ $command completion installed.
   Now run ". ~/${shellConfig(currentShell)}" to try it without restarting your shell.''');
}

uninstallScript(String command) {
  var uninstallCommand = '$command completion uninstall';
  print('Uninstalling completion for $command');

  var rcText = readRc(command);

  var begin = rcText.indexOf(getBeginMarker(command));
  var endMarker = getEndMarker(command);
  var end = rcText.indexOf(getEndMarker(command));
  if(begin == -1 || end == -1) {
    print(' ✗ $command completion was not installed. Nothing to do.');
    return;
  }
  end = end + endMarker.length;
  var prefix = rcText.substring(0, begin);
  var suffix = rcText.substring(end);
  shellRc.writeAsStringSync(prefix + suffix);
  print(' ✓ $command completion uninstalled.');
}

String currentShell = new RegExp(r'\/bin\/(\w+)').firstMatch(Platform.environment['SHELL']).group(1);
File shellRc = () {
  var fileName = '.' + currentShell + 'rc';
  var filePath = path.join(Platform.environment['HOME'], fileName);
  return new File(filePath);
}();

String readRc(String command) {
  if(shellRc.existsSync()) {
    return shellRc.readAsStringSync();
  }
  return null;
}

appendRc(String command, String text) {
  if(shellRc.existsSync()) {
    shellRc.openSync(mode: FileMode.APPEND).writeStringSync(text);
  }
}
