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
