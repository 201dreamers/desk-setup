#!/bin/sh
# Reopens a standalone (non-tmux) yazi in a new window of the most
# recently used tmux session, then quits the standalone one and closes its
# Ghostty window. A running program can't be handed to another
# terminal on macOS, so this is a relaunch: the folder and hovered file
# carry over, yazi tabs/selection/yank don't.
#
# Usage: to-tmux.sh <hovered path>   (bound to T in keymap.toml)
#
# Does nothing when yazi is already inside tmux.

[ -n "$TMUX" ] && exit 0

# T was pressed in the standalone window, so it's Ghostty's front window
# right now - remember it before anything below changes focus.
standalone_window=$(osascript -e 'tell application "Ghostty" to get id of front window')

# The yazi instance this runs under: the nearest ancestor named yazi.
yazi_pid=$PPID
while [ "$yazi_pid" -gt 1 ] && [ "$(basename "$(ps -o comm= -p "$yazi_pid")")" != yazi ]; do
    yazi_pid=$(ps -o ppid= -p "$yazi_pid" | tr -d ' ')
done

# yazi runs shell commands from its current directory. Given a file, yazi
# opens its folder with that file hovered; given a folder, it opens *inside*
# it - so a hovered folder (or an empty directory, with nothing hovered)
# reopens the current directory instead.
if [ -f "$1" ]; then
    target="$1"
else
    target="$PWD"
fi

# Don't leak the standalone-only flag into a tmux server started from here.
unset NO_TMUX_AUTOSTART

# The tmux window runs yazi and then a shell, so quitting yazi (q) leaves
# the window open at a prompt instead of closing it. $1 is the target.
YAZI_THEN_SHELL='yazi "$1"; exec zsh'

session=$(tmux list-sessions -F '#{session_activity} #{session_name}' 2>/dev/null \
    | sort -rn | head -n 1 | cut -d ' ' -f 2-)

if [ -n "$session" ]; then
    tmux new-window -t "$session:" -c "$PWD" zsh -ic "$YAZI_THEN_SHELL" zsh "$target"
else
    session=$(tmux new-session -d -P -F '#{session_name}' -c "$PWD" zsh -ic "$YAZI_THEN_SHELL" zsh "$target")
fi

# new-window already made the new window current in that session, so any
# client attached to it shows yazi. With no attached client, open a Ghostty
# window onto the session instead.
if [ -z "$(tmux list-clients -t "$session" 2>/dev/null)" ]; then
    # Typed into a plain shell rather than set as Ghostty's `command` (see
    # open-standalone.sh), and exec'd so the window closes on detach.
    osascript -e "tell application \"Ghostty\" to new window with configuration {environment variables:{\"NO_TMUX_AUTOSTART=1\"}, initial input:\"exec tmux attach -t '$session'
\"}"
fi
osascript -e 'tell application "Ghostty" to activate'

ya emit quit

# Close the standalone window once yazi has actually exited - closing it
# while yazi still runs would make Ghostty ask to confirm. Backgrounded and
# detached so it outlives yazi (and this script, which yazi spawned).
nohup sh -c '
    while kill -0 "$1" 2>/dev/null; do sleep 0.05; done
    osascript -e "tell application \"Ghostty\" to close window (first window whose id is \"$2\")"
' sh "$yazi_pid" "$standalone_window" >/dev/null 2>&1 &
