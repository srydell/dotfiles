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

list_sessions="tmux list-sessions -F \"#{session_id}${tab}#{session_name}\""

# Ignore global fzf options so typing, navigation, and acceptance stay predictable.
# --expect lets Ctrl-D exit fzf immediately (instead of running a shell action
# inside it) so the y/N prompt below runs in a normal foreground shell with a
# real controlling terminal, rather than fzf's execute() sandbox.
result=$(eval "$list_sessions" |
    FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE= fzf \
        --no-multi --layout=reverse \
        --delimiter="$tab" --with-nth=2 --nth=1 \
        --prompt='Session > ' \
        --bind='ctrl-j:down,ctrl-k:up,enter:accept' \
        --expect=ctrl-d \
        --preview='sh "$TMUX_SESSION_PICKER" --preview {1}' \
        --preview-window='right:60%:follow') || exit 0

key=$(printf '%s\n' "$result" | head -n 1)
selection=$(printf '%s\n' "$result" | tail -n +2)
[ -n "$selection" ] || exit 0
session_id=${selection%%"$tab"*}

if [ "$key" = 'ctrl-d' ]; then
    name=$(tmux display-message -p -t "$session_id" '#{session_name}')
    printf "Kill session '%s'? [y/N] " "$name"
    read -r answer
    case "$answer" in
        y|Y) tmux kill-session -t "$session_id" ;;
    esac
    exec sh "$0"
fi

tmux switch-client -c "$TMUX_PICKER_CLIENT" -t "$session_id"
