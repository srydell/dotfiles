# Load if not loaded
autoload -Uz compinit

# Rebuild an existing dump after 24 hours. The N qualifier makes a missing
# dump expand to nothing, allowing compinit -C to create it without an error.
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
	compinit
	touch "${ZDOTDIR}/.zcompdump"
else
	compinit -C
fi
