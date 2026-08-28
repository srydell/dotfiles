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
# split on the prompt-marker line, which is one or more $ (or # if root)
# followed by a space and then whatever was typed on that line - a
# terminal doesn't put the prompt on its own blank line, so anything typed
# after the "$ " appears on the *same* captured line as the prompt).
#
# Our two-line PROMPT (see prompt.zsh) always renders as:
#   <cwd/git info line>
#   $ <command that was typed>
# so the line right before a marker line always belongs to the *next*
# prompt, not to the previous command's output, and must be excluded too.
#
# Only works inside tmux, since that's what provides the scrollback capture.
edit-last-command-output() {
	if [[ "$TERM" == *tmux* ]]; then
		# `tac` isn't available on macOS (BSD userland), so track the last
		# two prompt-marker line numbers in a single forward pass instead of
		# reversing the stream.
		# `buftype=nofile` + `nomodified` mark this as a disposable scratch
		# buffer, so a plain `:q` quits without needing `:q!` (there's
		# nothing to save and nowhere to save it to anyway).
		tmux capture-pane -p -S - -E - -J | awk '
			/^[$#]+[[:space:]]/ { prev=cur; cur=NR }
			{ lines[NR] = $0 }
			END {
				for (i = prev + 1; i <= cur - 2; i++) print lines[i]
			}
		' | nvim -c 'set buftype=nofile bufhidden=wipe nomodified' -
	else
		echo
		print -Pn "%F{red}error: can't capture last command output outside of tmux%f"
		zle accept-line
	fi
}
zle -N edit-last-command-output
bindkey '^x^o' edit-last-command-output
