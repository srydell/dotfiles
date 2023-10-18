alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# -> Prevents accidentally clobbering files.
alias mkdir='mkdir -p'
alias ..='cd ..'

alias v=nvim
alias vi=nvim
alias vim=nvim
alias vimdiff='nvim -d'

alias irc='ssh -t weeberry "tmux attach" 2> /dev/null'

# Git commands
alias gs='git status'
alias ga='git add'
alias gp='git push'
alias gpb='git push origin $(git rev-parse --abbrev-ref HEAD):task/$(git rev-parse --abbrev-ref HEAD)'
