# If instant prompt script is available, use it.
# This makes the prompt available before all other config is fully loaded
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Install plugins if not installed
if [ ! -f $ZDOTDIR/antigen.sh ]; then
	# Install antibody
	# curl -L git.io/antigen > $ZDOTDIR/antigen.zsh
fi

source $ZDOTDIR/antigen.zsh
export ANTIBODY_HOME=${HOME}/.cache/antibody

antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting

# Directory movements
antigen bundle agkozak/zsh-z

antigen theme romkatv/powerlevel10k
antigen apply

# Load configs, platform specific files are in zsh.d/$(uname)
for ZSH_FILE in ${ZDOTDIR:-$HOME}/zsh.d{,/$(uname)}/*.zsh; do
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
