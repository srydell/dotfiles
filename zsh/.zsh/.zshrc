# Keychain only handles the latest gpg key
# LATEST_GPGKEY=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '($1 ~ "sec") { print $5 }' | tail -n 1)
# Control ssh-agent. Only handles keys listed here.
# To add a new key, add the name of the file after id_rsa if it is in ~/.ssh/
# or give an absolute path
# eval $(keychain --eval --quiet --ignore-missing --agents gpg,ssh id_rsa "$LATEST_GPGKEY")
# unset LATEST_GPGKEY

# Always prompt for gpg password in the terminal instead of gui popup
GPG_TTY="$(tty)"
export GPG_TTY

if [ ! -f $ZDOTDIR/zsh_plugins.sh ]; then
	fpath+=($ZDOTDIR/installs)
	autoload -Uz install_plugins
	install_plugins $ZDOTDIR/zsh_plugins.txt
fi
source $ZDOTDIR/zsh_plugins.sh

# Accept autosuggest with <C-SPACE>
bindkey '^ ' autosuggest-accept
# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Set up the prompt
autoload -Uz promptinit
promptinit
prompt pure

for ZSH_FILE in "${ZDOTDIR:-$HOME}"/zsh.d/*.zsh(N); do
	source "${ZSH_FILE}"
done
