# Install plugins if not installed
if [ ! -f $ZDOTDIR/zsh_plugins.sh ]; then
	fpath+=($ZDOTDIR/installs)
	autoload -Uz install_plugins
	install_plugins $ZDOTDIR/zsh_plugins.txt
fi
source $ZDOTDIR/zsh_plugins.sh

# Set up the prompt
autoload -Uz promptinit
promptinit
prompt pure

# Load configs, platform specific files are in zsh.d/$(uname)
for ZSH_FILE in ${ZDOTDIR:-$HOME}/zsh.d{,/$(uname)}/*.zsh; do
	source "${ZSH_FILE}"
done

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e
# Expand commands on space
bindkey " " magic-space
# Accept autosuggest with <C-SPACE>
bindkey '^ ' autosuggest-accept
