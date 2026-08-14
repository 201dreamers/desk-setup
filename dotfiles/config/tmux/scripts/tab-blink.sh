#!/bin/sh
# Mark / unmark the tmux window that hosts this AI agent as "waiting for input".
#
# Usage: tab-blink.sh set|clear
#
# Wired up from Claude Code hooks (see ~/.claude/settings.json). The tmux status
# line reads the per-window @ai_wait option and blinks the tab while it is set.
# A no-op outside tmux.

[ -n "$TMUX_PANE" ] || exit 0

case "$1" in
set)
	# Don't nag about a window the user is already looking at.
	looking=$(tmux display -p -t "$TMUX_PANE" '#{&&:#{window_active},#{session_attached}}' 2>/dev/null) || exit 0
	[ "$looking" = "1" ] && exit 0
	tmux set -w -t "$TMUX_PANE" @ai_wait 1 2>/dev/null
	;;
clear)
	tmux set -uw -t "$TMUX_PANE" @ai_wait 2>/dev/null
	;;
esac

exit 0
