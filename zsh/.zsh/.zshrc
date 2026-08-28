# Install plugins if not installed
if [[ ! -d "$ZDOTDIR/antidote" ]]; then
	# Install antidote
	git clone --depth=1 https://github.com/mattmc3/antidote.git "$ZDOTDIR/antidote"
	chmod +x "$ZDOTDIR/antidote/antidote"
fi

# Lazy-load antidote and generate the static load file only when needed
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
	(
		source "$ZDOTDIR/antidote/antidote.zsh"
		antidote bundle <"${zsh_plugins}.txt" >"${zsh_plugins}.zsh"
	)
fi
source "${zsh_plugins}.zsh"

# Use emacs keybindings even if our EDITOR is set to vi.
# Must run before the zsh.d loop below: `bindkey -e` resets the *entire*
# keymap to stock emacs bindings, which would clobber any custom `bindkey`
# calls (e.g. keys.zsh) if it ran after them.
bindkey -e

# Load configs, platform specific files are in zsh.d/$(uname)
for ZSH_FILE in ${ZDOTDIR:-$HOME}/zsh.d{/$(uname),}/*.zsh; do
	source "${ZSH_FILE}"
done

zstyle ':completion:*' menu select

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

export MANPAGER='nvim +Man!'
export MANWIDTH=999

# Make vim default editor
export VISUAL=nvim
export EDITOR=$VISUAL

export LC_ALL=en_US.UTF-8

# Let fzf fuzzy finder use ripgrep to search for the files.
# This respects .gitignore and the like
export FZF_DEFAULT_COMMAND='rg --files'

export GOPATH="$HOME/.go"
export PATH="$PATH:$GOPATH/bin"
# Place for custom scripts
export PATH="$HOME/bin:$PATH"
# Place for custom executables used by vim
export PATH="$PATH:$HOME/.vim/integrations/bin"
# Fuzzy finder binary
export PATH="$HOME/.vim/pack/minpac/start/fzf/bin/:$PATH"

# Set config path
export XDG_CONFIG_HOME=$HOME/.config

# pip
export PATH="$PATH:$HOME/.local/bin"

# Machine-local overrides and secrets (untracked, lives directly in $HOME).
# Sourced last so it can override anything set above.
if [ -f ~/.zshrc.local ]; then
	source ~/.zshrc.local
fi
