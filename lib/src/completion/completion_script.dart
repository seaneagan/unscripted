
part of unscripted.completion;

String getScriptOutput (String command) {

  var completionCommand = '$command completion';
  var func = '_${command.replaceAll(new RegExp(r'[.-]'), '_')}_completion';

  return '''

###-begin-$command-completion-###
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
###-end-$command-completion-###
''';
}
