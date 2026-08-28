# Simple, fast, native zsh prompt (replaces powerlevel10k).
#
# Layout:
#   <cwd> <git branch> <status markers>       [duration of last command]
#   <one $ per nested shell level, or # if running as root>
#
# Status markers (only shown when non-empty, nothing at all on a clean,
# up-to-date repo): ✖ conflict, ● unstaged changes, ⇡N/⇣N commits
# ahead/behind upstream.
#
# - The git segment is computed in a background subshell (via process
#   substitution + a `zle -F` fd watcher, not a persistent zsh-async/zpty
#   worker) so the prompt is drawn instantly and never blocks on `git
#   status`, even in huge repos, while avoiding zpty's job-control noise.
# - OSC 133 "semantic prompt" escape sequences mark prompt/command/output
#   boundaries (FTCS_PROMPT_START/COMMAND_START/COMMAND_EXECUTED/
#   COMMAND_FINISHED) so terminals that understand them (iTerm2, kitty,
#   WezTerm, VS Code, ...) can jump between commands, select just a
#   command's output, and show exit-status gutter marks. See:
#   https://gitlab.freedesktop.org/Per_Bothner/specifications/blob/master/proposals/semantic-prompts.md
# - Colors match the gruvbox (dark) palette used for Neovim in
#   vim/.config/nvim/lua/srydell/colorscheme.lua.
setopt PROMPT_SUBST
zmodload zsh/datetime
autoload -Uz add-zsh-hook

typeset -g _prompt_gruvbox_blue='#83a598'
typeset -g _prompt_gruvbox_green='#b8bb26'
typeset -g _prompt_gruvbox_red='#fb4934'
typeset -g _prompt_gruvbox_orange='#fe8019'
typeset -g _prompt_gruvbox_aqua='#8ec07c'

typeset -g _prompt_git_info=""
typeset -g _prompt_duration=""
typeset -g _prompt_has_run=0
typeset -g _prompt_exit_code=0
typeset -F _prompt_cmd_start=0

# OSC 133 semantic-prompt markers.
typeset -g _osc_prompt_start=$'\e]133;A\a' # FTCS_PROMPT_START
typeset -g _osc_prompt_end=$'\e]133;B\a'   # FTCS_COMMAND_START
typeset -g _osc_output_start=$'\e]133;C\a' # FTCS_COMMAND_EXECUTED

# Formats $1 (elapsed seconds) into $_prompt_duration, e.g. "1d2h3m4s" or
# "4.56s". Sets the global directly instead of `print`-ing + capturing via
# `$(...)`, since forking a subshell here (or anywhere else in the render
# path) can race with zsh's background-job notifications and corrupt the
# prompt line being drawn.
_prompt_format_duration() {
	local total=$1
	integer days hours mins secs
	local out=""
	(( days = total / 86400 ))
	(( hours = (total - days * 86400) / 3600 ))
	(( mins = (total - days * 86400 - hours * 3600) / 60 ))
	local secs_f=$(( total - days * 86400 - hours * 3600 - mins * 60 ))
	(( days )) && out+="${days}d"
	(( hours )) && out+="${hours}h"
	(( mins )) && out+="${mins}m"
	if [[ -z $out ]]; then
		printf -v out "%.2fs" $secs_f
	else
		(( secs = secs_f ))
		out+="${secs}s"
	fi
	_prompt_duration=$out
}

# Builds $PROMPT/$RPROMPT using only parameter expansion (no `$(...)` /
# backtick command substitution anywhere), since every command substitution
# forks a subshell, and forking from here — especially from the async
# `zle -F` callback — can race with zsh's background-job notifications and
# corrupt the prompt line being drawn.
_prompt_render() {
	local marker=""
	(( _prompt_has_run )) && marker=$'\e]133;D;'"${_prompt_exit_code}"$'\a'

	# One $ per nested shell level (tmux itself starts a shell, so don't
	# count that extra level while inside it); # instead when running as
	# root. Built with a plain loop (no `$(...)` fork). Each char is
	# backslash-escaped: PROMPT_SUBST re-parses the final prompt string for
	# parameter expansion, so two or more raw, unescaped `$` characters in
	# a row (SHLVL >= 2) get misread as the `$$` (current PID) parameter
	# instead of staying literal — the escaping prevents that.
	local lvl=$SHLVL
	[[ -n $TMUX ]] && (( lvl-- ))
	(( lvl < 1 )) && lvl=1
	local char='$'
	(( EUID == 0 )) && char='#'
	local nesting="" i
	for (( i = 0; i < lvl; i++ )); do nesting+="\\$char"; done

	PROMPT="%{${marker}${_osc_prompt_start}%}%F{$_prompt_gruvbox_blue}%~%f${_prompt_git_info}
%F{$_prompt_gruvbox_orange}${nesting}%f %{${_osc_prompt_end}%}"

	RPROMPT="%F{$_prompt_gruvbox_aqua}${_prompt_duration}%f"
}

# Runs inside a background subshell (via process substitution), so blocking
# git calls here never stall the interactive shell.
#
# Shows nothing at all beyond the branch name when the repo is clean and in
# sync with its upstream. Otherwise shows a marker per condition:
#   ✖ merge conflict   ● unstaged changes   ⇡N/⇣N commits ahead/behind
_prompt_git_info_worker() {
	cd -q "$1" 2>/dev/null || return
	local branch
	branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch=$(git rev-parse --short HEAD 2>/dev/null)
	[[ -z $branch ]] && return

	local flags
	flags=$(git status --porcelain --ignore-submodules 2>/dev/null | awk '
		{
			x = substr($0, 1, 1); y = substr($0, 2, 1)
			if (x == "?" && y == "?") next
			if (x == "U" || y == "U" || (x == "A" && y == "A") || (x == "D" && y == "D")) conflict = 1
			if (y != " ") unstaged = 1
		}
		END { printf "%d%d", unstaged, conflict }
	')
	local unstaged=${flags:0:1} conflict=${flags:1:1}

	local marks=""
	(( conflict )) && marks+=" %F{$_prompt_gruvbox_red}✖%f"
	(( unstaged )) && marks+=" %F{$_prompt_gruvbox_red}●%f"

	local ahead_behind
	ahead_behind=$(git rev-list --left-right --count 'HEAD...@{u}' 2>/dev/null)
	if [[ -n $ahead_behind ]]; then
		local ahead=${ahead_behind%%[[:space:]]*} behind=${ahead_behind##*[[:space:]]}
		(( ahead )) && marks+=" %F{$_prompt_gruvbox_aqua}⇡${ahead}%f"
		(( behind )) && marks+=" %F{$_prompt_gruvbox_aqua}⇣${behind}%f"
	fi

	print -n " %F{$_prompt_gruvbox_green}${branch}%f${marks}"
}

_prompt_async_callback() {
	local fd=$1
	local info
	# Slurp whatever is available; our worker only ever writes once, right
	# before exiting, so this returns promptly rather than blocking.
	IFS= read -r -u $fd info
	zle -F $fd
	exec {fd}<&-
	(( _prompt_git_fd == fd )) && _prompt_git_fd=0
	_prompt_git_info=$info
	_prompt_render
	zle && zle reset-prompt
}

_prompt_clear_git_info_on_chpwd() {
	_prompt_git_info=""
}

_prompt_preexec() {
	_prompt_cmd_start=$EPOCHREALTIME
	_prompt_has_run=1
	print -n "$_osc_output_start"
}

_prompt_precmd() {
	# Capture immediately: this must be the very first thing that runs in
	# precmd, before anything else has a chance to reset $?.
	_prompt_exit_code=$?

	_prompt_duration=""
	if (( _prompt_has_run )); then
		local elapsed=$(( EPOCHREALTIME - _prompt_cmd_start ))
		# Only bother showing durations worth caring about.
		(( elapsed >= 5 )) && _prompt_format_duration $elapsed
	fi

	_prompt_render
}

add-zsh-hook preexec _prompt_preexec
add-zsh-hook precmd _prompt_precmd
add-zsh-hook chpwd _prompt_clear_git_info_on_chpwd

typeset -gi _prompt_git_fd=0

_prompt_trigger_git_async() {
	# Cancel any still-in-flight lookup for a directory we've already left.
	if (( _prompt_git_fd )); then
		zle -F $_prompt_git_fd 2>/dev/null
		exec {_prompt_git_fd}<&- 2>/dev/null
		_prompt_git_fd=0
	fi
	# `no_monitor` keeps this fork out of the job table entirely, so it
	# never prints a "[1]  <pid>  done" job-control notification of its
	# own when it finishes.
	setopt localoptions no_monitor no_notify
	exec {_prompt_git_fd}< <(_prompt_git_info_worker "$PWD")
	zle -F $_prompt_git_fd _prompt_async_callback
}
add-zsh-hook precmd _prompt_trigger_git_async
