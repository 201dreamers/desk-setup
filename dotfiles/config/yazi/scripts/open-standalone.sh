#!/bin/sh
# Opens yazi in a new Ghostty window in the home directory, outside tmux.
#
# Usage: open-standalone.sh   (bound to ctrl+cmd-y in skhdrc)
#
# Opens a plain shell window and types `yazi` into it, rather than
# setting Ghostty's `command`: Ghostty keeps a `command` window open on a
# "Process exited" prompt after it ends (even with wait after command off).
# This way quitting yazi (q) leaves a usable shell in the window, and T
# closes the window outright once it has reopened yazi in tmux (see
# to-tmux.sh). Going through the shell also gives yazi PATH/EDITOR from
# zshrc; NO_TMUX_AUTOSTART stops zshrc from attaching to tmux on the way.

osascript <<OSA
tell application "Ghostty"
    new window with configuration {initial working directory:"$HOME", environment variables:{"NO_TMUX_AUTOSTART=1"}, initial input:"yazi
"}
    activate
end tell
OSA
