# Simple, fast, native zsh prompt (replaces powerlevel10k).
#
# Layout:
#   <cwd>                                  <duration of last command> [branch●●]
#   <one $ per nested shell level, or # if running as root>
#
# Timing + git segment are right-aligned on the *first* line (alongside cwd),
# not the second (input) line where $RPROMPT would otherwise put them: since
# PROMPT spans two lines, plain RPROMPT is drawn next to the last line. So
# instead this saves the cursor, jumps to the right column with an absolute
# cursor-position escape, prints the segment, then restores the cursor, all
# before the newline into the second line. Nothing is rendered at all when
# there's no timing to show and the cwd isn't inside a git repo (no empty
# "[]" brackets, no stray leading space).
#
# Git segment (mimics wincent/wincent's style: https://github.com/wincent/wincent),
# rendered as "[branch●●]" with one small colored dot per condition (nothing
# at all shown for a clean repo with no dots to add):
#   green ● staged changes, red ● unstaged changes, blue ● untracked files.
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
typeset -gi _prompt_git_info_width=0
typeset -g _prompt_duration=""
typeset -g _prompt_has_run=0
typeset -g _prompt_exit_code=0
typeset -F _prompt_cmd_start=0

# OSC 133 semantic-prompt markers.
typeset -g _osc_prompt_start=$'\e]133;A\a' # FTCS_PROMPT_START
typeset -g _osc_prompt_end=$'\e]133;B\a'   # FTCS_COMMAND_START
typeset -g _osc_output_start=$'\e]133;C\a' # FTCS_COMMAND_EXECUTED

# DECSC/DECRC (save/restore cursor) and CSI sequences used to right-align
# the first-line segment below need a real ESC byte: a plain "..." string
# leaves a literal backslash-e in zsh instead, so this must come from a
# $'...'-quoted literal.
typeset -g _term_esc=$'\e'

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

	# Build the right-hand segment for the first line: duration (if any),
	# then the git indicator (if any), tracking its *plain* display width
	# alongside it (color escapes like %F{...}/%f take up zero columns, so
	# ${#...} on the colored text would overcount).
	local rhs_content="" rhs_width=0
	if [[ -n $_prompt_duration ]]; then
		rhs_content+="%F{$_prompt_gruvbox_aqua}${_prompt_duration}%f"
		(( rhs_width += ${#_prompt_duration} ))
	fi
	if (( _prompt_git_info_width > 0 )); then
		if [[ -n $rhs_content ]]; then
			rhs_content+=" "
			(( rhs_width += 1 ))
		fi
		rhs_content+="$_prompt_git_info"
		(( rhs_width += _prompt_git_info_width ))
	fi

	local rhs=""
	if (( rhs_width > 0 && COLUMNS > rhs_width )); then
		# %{...%} tells zle these escapes occupy zero columns, so its own
		# cursor math for the first line (where the newline into the second
		# line happens) is unaffected: DECSC/DECRC save/restore the cursor
		# around an absolute column jump (CSI n G) to the right edge of the
		# terminal, so this renders on the first line regardless of where
		# RPROMPT would otherwise place it.
		rhs="%{${_term_esc}7%}%{${_term_esc}[$(( COLUMNS - rhs_width + 1 ))G%}${rhs_content}%{${_term_esc}8%}"
	fi

	PROMPT="%{${marker}${_osc_prompt_start}%}%F{$_prompt_gruvbox_blue}%~%f${rhs}
%F{$_prompt_gruvbox_orange}${nesting}%f %{${_osc_prompt_end}%}"

	RPROMPT=""
}

# Runs inside a background subshell (via process substitution), so blocking
# git calls here never stall the interactive shell.
#
# Prints "<plain-width>|[branch●●]" (wincent/wincent style) — the plain width
# lets the renderer right-align this alongside the cwd without miscounting
# the zero-width color escapes. One small colored dot per condition, nothing
# at all (not even the branch) beyond a plain "return" for a non-git cwd:
#   green ● staged changes   red ● unstaged changes   blue ● untracked files
_prompt_git_info_worker() {
	cd -q "$1" 2>/dev/null || return
	local branch
	branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch=$(git rev-parse --short HEAD 2>/dev/null)
	[[ -z $branch ]] && return

	local flags
	flags=$(git status --porcelain --ignore-submodules 2>/dev/null | awk '
		{
			x = substr($0, 1, 1); y = substr($0, 2, 1)
			if (x == "?" && y == "?") { untracked = 1; next }
			if (x != " ") staged = 1
			if (y != " ") unstaged = 1
		}
		END { printf "%d%d%d", staged, unstaged, untracked }
	')
	local staged=${flags:0:1} unstaged=${flags:1:1} untracked=${flags:2:1}

	# Small bullet (•, U+2022) rather than the larger circle (●, U+25CF), so
	# multiple adjacent dots don't visually overlap in most terminal fonts.
	local dots="" dot_count=0
	if (( staged )); then
		dots+="%F{$_prompt_gruvbox_green}•%f"
		(( dot_count++ ))
	fi
	if (( unstaged )); then
		dots+="%F{$_prompt_gruvbox_red}•%f"
		(( dot_count++ ))
	fi
	if (( untracked )); then
		dots+="%F{$_prompt_gruvbox_blue}•%f"
		(( dot_count++ ))
	fi

	local width=$(( 2 + ${#branch} + dot_count )) # "[" + branch + dots + "]"
	print -n "${width}|[${branch}${dots}]"
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
	if [[ -z $info ]]; then
		_prompt_git_info_width=0
		_prompt_git_info=""
	else
		_prompt_git_info_width=${info%%|*}
		_prompt_git_info=${info#*|}
	fi
	_prompt_render
	zle && zle reset-prompt
}

_prompt_clear_git_info_on_chpwd() {
	_prompt_git_info=""
	_prompt_git_info_width=0
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
