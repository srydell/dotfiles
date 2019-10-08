# Install plugins if not installed
if [ ! -f $ZDOTDIR/zsh_plugins.sh ]; then
	fpath+=($ZDOTDIR/installs)
	autoload -Uz install_plugins
	install_plugins $ZDOTDIR/zsh_plugins.txt
fi
source $ZDOTDIR/zsh_plugins.sh

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

# To customize prompt, run `p10k configure` or edit ~/.zsh/.p10k.zsh.
[[ -f ~/.zsh/.p10k.zsh ]] && source ~/.zsh/.p10k.zsh
