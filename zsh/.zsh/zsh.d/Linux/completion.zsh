# Load if not loaded
autoload -Uz compinit

# Only load completions once a day
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
	compinit
	touch ${ZDOTDIR}/.zcompdump
else
	compinit -C
fi
