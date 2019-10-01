# Load if not loaded
autoload -Uz compinit

# Only load completions once a day
if [ $(date +'%j') != $(stat -f '%Sm' -t '%j' $ZDOTDIR/.zcompdump) ]; then
	compinit
	touch $ZDOTDIR/.zcompdump
else
	compinit -C
fi
