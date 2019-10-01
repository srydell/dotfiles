# Load if not loaded
autoload -Uz compinit

# Only load completions once a day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
	compinit
	touch .zcompdump
else
	compinit -C
fi
