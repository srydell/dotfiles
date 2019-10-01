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
