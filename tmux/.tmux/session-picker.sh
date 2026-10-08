#!/bin/sh
# Keep session IDs hidden in fzf so names containing spaces remain safe targets.
# Preview the selected session's windows and the contents of its active pane.
if [ "${1-}" = --preview ]; then
    tmux list-windows -t "$2" -F '#{window_index}: #{window_name}#{?window_active, (active),} [#{window_panes} panes]'
    printf '\n'
    tmux capture-pane -ep -t "$2:" -S -200
    exit
fi

if ! command -v fzf >/dev/null 2>&1; then
    tmux display-message 'Session picker requires fzf on PATH'
    exit 1
fi

tab=$(printf '\t')
TMUX_SESSION_PICKER=$0
export TMUX_SESSION_PICKER

# Ignore global fzf options so typing, navigation, and acceptance stay predictable.
selection=$(tmux list-sessions -F "#{session_id}${tab}#{session_name}${tab}#{session_windows} windows#{?session_attached, (attached),}" |
    FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE= fzf \
        --no-multi --layout=reverse \
        --delimiter="$tab" --with-nth=2.. --nth=1 \
        --prompt='Session > ' \
        --header='Ctrl-j/k: down/up | Enter: switch | Esc: cancel' \
        --bind='ctrl-j:down,ctrl-k:up,enter:accept' \
        --preview='sh "$TMUX_SESSION_PICKER" --preview {1}' \
        --preview-window='right:60%') || exit 0

[ -n "$selection" ] || exit 0
tmux switch-client -c "$TMUX_PICKER_CLIENT" -t "${selection%%"$tab"*}"
