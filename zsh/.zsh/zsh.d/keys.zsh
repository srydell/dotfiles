# Keychain only handles the latest gpg key
# LATEST_GPGKEY=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '($1 ~ "sec") { print $5 }' | tail -n 1)
# Control ssh-agent. Only handles keys listed here.
# To add a new key, add the name of the file after id_rsa if it is in ~/.ssh/
# or give an absolute path
# eval $(keychain --eval --quiet --ignore-missing --agents gpg,ssh id_rsa "$LATEST_GPGKEY")
if (( $+commands[keychain] )); then
	# Skip re-running keychain (~170ms) when a valid agent socket is
	# already inherited from the environment (e.g. a previous shell in
	# this session already set one up). `ssh-add -l` exits 2 when it
	# cannot reach the agent at all.
	agent_ok=0
	if [[ -n $SSH_AUTH_SOCK && -S $SSH_AUTH_SOCK ]]; then
		ssh-add -l &>/dev/null
		(( $? != 2 )) && agent_ok=1
	fi
	(( agent_ok )) || eval "$(keychain --eval --quiet --ignore-missing id_rsa)"
	unset agent_ok
fi
# unset LATEST_GPGKEY

# Always prompt for gpg password in the terminal instead of gui popup
# export GPG_TTY=$(tty)

# unset DISPLAY

# gpg-connect-agent updatestartuptty /bye > /dev/null

# Edit the current command line in $EDITOR (built-in zsh widget).
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^x' edit-command-line

# Capture the previous command's output (via the tmux pane's scrollback,
# split on the prompt-marker line, which is one or more $ (or # if root))
# and open it in nvim for review/editing. Anchored to a line consisting
# solely of $/# so it doesn't false-match those characters in normal output.
# Only works inside tmux, since that's what provides the scrollback capture.
edit-last-command-output() {
	if [[ "$TERM" == *tmux* ]]; then
		tmux capture-pane -p -S - -E - -J | tac | awk '
			found && !/^[$#]+[[:space:]]*$/ { print }
			/^[$#]+[[:space:]]*$/ && !found { found=1; next }
			/^[$#]+[[:space:]]*$/ && found { exit }
		' | tac | nvim -
	else
		echo
		print -Pn "%F{red}error: can't capture last command output outside of tmux%f"
		zle accept-line
	fi
}
zle -N edit-last-command-output
bindkey '^x^o' edit-last-command-output
