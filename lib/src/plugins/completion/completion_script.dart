
library unscripted.plugins.completion.completion_script;

import 'dart:io';

import 'package:path/path.dart' as path;

String getMarker(String command, String type) => '###-$type-$command-completion-###';
String getBeginMarker(String command) => '\n' + getMarker(command, 'begin');
String getEndMarker(String command) => getMarker(command, 'end') + '\n';

String getScriptOutput (String command, String completionSyntax) {

  var completionCommand = '$command $completionSyntax';
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

installScript(String command, String completionSyntax) {
  scriptInstallation(
      'install',
      command,
      completionSyntax,
      'Either run `. ~/${_shellConfig(currentShell)}` or start a new shell to try out',
      (command, rcText) {
        if(rcText == null) {
          var fileName = path.basename(shellRc.path);
          throw "No $fileName file. You'll have to instead run: $command $completionSyntax >> ~/$fileName";
        }
        var parts = rcText.split(getBeginMarker(command));
        return parts.length >= 2;
      },
      (command, completionSyntax, rcText) {
        appendRc(command, getScriptOutput(command, completionSyntax));
      });
}

uninstallScript(String command, String completionSyntax) {
  scriptInstallation(
      'uninstall',
      command,
      completionSyntax,
      '',
      (command, rcText) {
        var parts = rcText.split(getBeginMarker(command));
        return parts.length < 2;
      },
      (command, completionSyntax, rcText) {
        var begin = rcText.indexOf(getBeginMarker(command));
        var endMarker = getEndMarker(command);
        var end = rcText.indexOf(getEndMarker(command));
        end = end + endMarker.length;
        var prefix = rcText.substring(0, begin);
        var suffix = rcText.substring(end);
        shellRc.writeAsStringSync(prefix + suffix);
      });
}

String currentShell = new RegExp(r'\/bin\/(\w+)').firstMatch(Platform.environment['SHELL']).group(1);
File shellRc = () {
  var fileName = '.' + currentShell + 'rc';
  var filePath = path.join(Platform.environment['HOME'], fileName);
  return new File(filePath);
}();

scriptInstallation(String name, String command, String completionSyntax, String postActionMessage, bool alreadyDone(String command, String rcText), bool action(String command, String completionSyntax, String rcText)) {
  print('${name}ing completion for $command');
  var rcText = readRc();
  if(alreadyDone(command, rcText)) {
    print(' ✗ $command completion was already ${name}ed. Nothing to do.');
    return;
  }
  action(command, completionSyntax, rcText);
  print('''
 ✓ $command completion ${name}ed.''');
  if(postActionMessage.isNotEmpty) {
    print('   $postActionMessage');
  }
}

String readRc() {
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

String _shellConfig(shell) => '.${shell}rc';
