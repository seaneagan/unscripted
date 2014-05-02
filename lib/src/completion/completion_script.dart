
part of unscripted.completion;

void getScriptOutput (String command) {

  var completionCommand = '$command completion';
  var func = '_${command}_completion';

    var script = '''
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
    IFS=\$'\n' COMPREPLY=(\$(COMP_CWORD="\$COMP_CWORD" \
                           COMP_LINE="\$COMP_LINE" \
                           COMP_POINT="\$COMP_POINT" \
                           $completionCommand -- "\${COMP_WORDS[@]}" \
                           2>/dev/null)) || return \$?
    IFS="\$si"
  }
  complete -F $func $command
elif type compdef &>/dev/null; then
  $func() {
    si=\$IFS
    compadd -- \$(COMP_CWORD=\$((CURRENT-1)) \
                 COMP_LINE=\$BUFFER \
                 COMP_POINT=0 \
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
    IFS=\$'\n' reply=(\$(COMP_CWORD="\$cword" \
                       COMP_LINE="\$line" \
                       COMP_POINT="\$point" \
                       $completionCommand -- "\${words[@]}" \
                       2>/dev/null)) || return \$?
    IFS="\$si"
  }
  compctl -K $func $command
fi
###-end-$command-completion-###
''';
}

