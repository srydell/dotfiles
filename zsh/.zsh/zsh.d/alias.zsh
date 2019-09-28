alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# -> Prevents accidentally clobbering files.
alias mkdir='mkdir -p'
alias ..='cd ..'

alias v=vim

alias irc='ssh -t weeberry "tmux attach" 2> /dev/null'

# Git commands
alias gs='git status'
alias ga='git add'
alias gp='git push'
alias gpb='git push origin $(git rev-parse --abbrev-ref HEAD):task/$(git rev-parse --abbrev-ref HEAD)'
case "$(uname)" in
	Linux )
		alias ls='ls --color=auto'
		# ll : directories first, with alphanumeric sorting:
		alias ll="ls -lv --group-directories-first"
		# Recursive
		alias lr='ll -R'
		# Show hidden files
		alias la='ll -A'

		# Use fc to repeat last command
		# Alternatively add " 2>/dev/null" to not
		# rewrite the last command in prompt
		alias sa="fc -e : -1"
		# Rerun the last two commands
		alias ssa="fc -e : -2 -1"
		;;
	Darwin )
		alias ls='ls -G'

		alias mupdf='mupdf-gl'
		;;
esac
