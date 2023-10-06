# If instant prompt script is available, use it.
# This makes the prompt available before all other config is fully loaded
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Install plugins if not installed
if [ ! -d $ZDOTDIR/antidote ]; then
	# Install antidote
	git clone --depth=1 https://github.com/mattmc3/antidote.git $ZDOTDIR/antidote
	chmod +x $ZDOTDIR/antidote/antidote
fi

 # Lazy-load antidote and generate the static load file only when needed
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
	(
		source $ZDOTDIR/antidote/antidote.zsh
		antidote bundle <${zsh_plugins}.txt >${zsh_plugins}.zsh
	)
fi
source ${zsh_plugins}.zsh

# Load configs, platform specific files are in zsh.d/$(uname)
for ZSH_FILE in ${ZDOTDIR:-$HOME}/zsh.d{/$(uname),}/*.zsh; do
	source "${ZSH_FILE}"
done

zstyle ':completion:*' menu select

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e
# Expand commands on space
bindkey " " magic-space
# Accept autosuggest with <C-SPACE>
bindkey '^ ' autosuggest-accept
# Use shift+tab to autocomplete backwards
bindkey '^[[Z' reverse-menu-complete

setopt CORRECT          # Correct command names
setopt ALWAYS_TO_END    # Cursor moves to end of completion
setopt AUTO_LIST        # List choices
setopt AUTO_MENU        # Automatically use menu
setopt AUTO_PARAM_SLASH # If completion is directory add trailing slash
setopt COMPLETE_IN_WORD # Also complete in word
setopt PATH_DIRS        # Path search even on command names with slashes
unsetopt CASE_GLOB      # Globbing case insensitively
unsetopt MENU_COMPLETE  # Always display menu, don't directly insert

# To customize prompt, run `p10k configure` or edit ~/.zsh/.p10k.zsh.
[[ -f ~/.zsh/.p10k.zsh ]] && source ~/.zsh/.p10k.zsh
