# Simple, fast, native zsh prompt (replaces powerlevel10k).
# Shows: <cwd> <git branch> <red dot if repo is dirty>
#        ❯
#
# Modeled after wincent/wincent's prompt: the git segment is computed in a
# persistent background worker (zsh-async) so the prompt is drawn instantly
# and never blocks on `git status`, even in huge repos. The git segment
# appears/updates a moment later via `zle reset-prompt`.
#
# Colors match the gruvbox (dark) palette used for Neovim in
# vim/.config/nvim/lua/srydell/colorscheme.lua.
setopt PROMPT_SUBST
autoload -Uz add-zsh-hook

typeset -g _prompt_gruvbox_blue='#83a598'
typeset -g _prompt_gruvbox_green='#b8bb26'
typeset -g _prompt_gruvbox_red='#fb4934'
typeset -g _prompt_gruvbox_orange='#fe8019'

typeset -g _prompt_git_info=""

_prompt_render() {
	PROMPT="%F{$_prompt_gruvbox_blue}%~%f${_prompt_git_info}
%F{$_prompt_gruvbox_orange}❯%f "
}

# Runs inside the async worker process, so blocking git calls here never
# stall the interactive shell.
_prompt_git_info_worker() {
	cd -q "$1" 2>/dev/null || return
	local branch
	branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch=$(git rev-parse --short HEAD 2>/dev/null)
	[[ -z $branch ]] && return

	local dirty=""
	[[ -n $(git status --porcelain --ignore-submodules 2>/dev/null) ]] && dirty=" %F{$_prompt_gruvbox_red}●%f"

	print -n " %F{$_prompt_gruvbox_green}${branch}%f${dirty}"
}

_prompt_async_callback() {
	local job=$1 return_code=$2 stdout=$3
	if [[ $job == '[async]' ]]; then
		if (( return_code == 2 || return_code == 3 || return_code == 130 )); then
			# Worker died; restart it.
			async_stop_worker prompt_git
			async_start_worker prompt_git
			async_register_callback prompt_git _prompt_async_callback
		fi
		return
	fi
	_prompt_git_info=$stdout
	_prompt_render
	zle && zle reset-prompt
}

_prompt_clear_git_info_on_chpwd() {
	_prompt_git_info=""
}

if (( $+functions[async_start_worker] )) || { autoload -Uz async && async; }; then
	async_start_worker prompt_git
	async_register_callback prompt_git _prompt_async_callback
	add-zsh-hook chpwd _prompt_clear_git_info_on_chpwd

	precmd() {
		_prompt_render
		async_flush_jobs prompt_git
		async_job prompt_git _prompt_git_info_worker "$PWD"
	}
else
	# zsh-async unavailable; fall back to a synchronous (still fast for
	# typical repos) prompt.
	precmd() {
		_prompt_git_info=$(_prompt_git_info_worker "$PWD")
		_prompt_render
	}
fi
