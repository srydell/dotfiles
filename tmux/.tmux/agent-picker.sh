#!/bin/sh
# Keep pane IDs hidden in fzf so names containing spaces remain safe targets.
# Preview the selected pane's contents.
if [ "${1-}" = --preview ]; then
    # No -S: agent CLIs render a full-screen (alternate-screen) UI, so
    # scrollback history would just mix in stale pre-launch terminal output.
    tmux capture-pane -ep -t "$2"
    exit
fi

if ! command -v fzf >/dev/null 2>&1; then
    tmux display-message 'Agent picker requires fzf on PATH'
    exit 1
fi

# Commands considered "AI agents" - extend as needed.
agent_commands='claude copilot codex'

# Heuristics for classifying an agent pane's current status from its visible
# screen content. Tune these patterns if a CLI's wording changes.
input_pattern='wants to run|allow this (command|action)|yes, always|do you want to|\(y/n\)|to navigate.*to select'
working_pattern='working.*(esc esc interrupt|esc to interrupt)|esc (esc )?interrupt.*working'

# Classify a single pane's status as INPUT (needs approval/a decision),
# WORKING (actively processing), or READY (idle, waiting for a prompt).
pane_status() {
    # No -e: ANSI color codes can be inserted mid-word by the agent's UI,
    # which would otherwise break substring matches against the patterns above.
    content=$(tmux capture-pane -p -t "$1")
    # Approval/choice dialogs render as a modal near the bottom of the screen;
    # restricting the INPUT check to the tail avoids matching unrelated text
    # (e.g. earlier conversation content) elsewhere on screen.
    if printf '%s\n' "$content" | tail -n 15 | grep -qiE "$input_pattern"; then
        printf 'INPUT'
    elif printf '%s\n' "$content" | grep -qiE "$working_pattern"; then
        printf 'WORKING'
    else
        printf 'READY'
    fi
}

tab=$(printf '\t')
TMUX_AGENT_PICKER=$0
export TMUX_AGENT_PICKER

match_pattern=$(printf '%s' "$agent_commands" | tr ' ' '|')

agent_panes=$(tmux list-panes -a -F "#{pane_id}${tab}#{session_name}:#{window_index}.#{pane_index}${tab}#{window_name}${tab}#{pane_current_command}${tab}#{pane_current_path}" |
    awk -F"$tab" -v pat="^($match_pattern)\$" '$4 ~ pat')

if [ -z "$agent_panes" ]; then
    tmux display-message "No agent panes found (looking for: $agent_commands)"
    exit 0
fi

panes=$(printf '%s\n' "$agent_panes" | while IFS="$tab" read -r pane_id location window cmd path; do
    status=$(pane_status "$pane_id")
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$pane_id" "$location" "$status" "$window" "$cmd" "$path"
done | awk -F"$tab" -v OFS="$tab" '
    { rows[NR] = $0; loc[NR] = $2; if (length($2) > maxloc) maxloc = length($2) }
    END {
        for (i = 1; i <= NR; i++) {
            n = split(rows[i], f, FS)
            printf "%s" OFS "%-" maxloc "s" OFS "%-7s" OFS "%s" OFS "%s" OFS "%s\n", f[1], f[2], f[3], f[4], f[5], f[6]
        }
    }')

# Ignore global fzf options so typing, navigation, and acceptance stay predictable.
selection=$(printf '%s\n' "$panes" |
    FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE= fzf \
        --no-multi --layout=reverse \
        --delimiter="$tab" --with-nth=2,3 --nth=1,2 \
        --prompt='Agent > ' \
        --bind='ctrl-j:down,ctrl-k:up,enter:accept' \
        --preview='sh "$TMUX_AGENT_PICKER" --preview {1}' \
        --preview-window='right:60%:follow') || exit 0

[ -n "$selection" ] || exit 0
pane_id=${selection%%"$tab"*}
session=$(tmux display-message -p -t "$pane_id" '#{session_name}')
tmux switch-client -c "$TMUX_PICKER_CLIENT" -t "$session"
tmux select-window -t "$pane_id"
tmux select-pane -t "$pane_id"
