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

# Git commands
alias gs='git status'
alias ga='git add'
alias gp='git push origin HEAD:$(git branch --show-current)'
