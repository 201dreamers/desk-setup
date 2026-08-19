-- Two independent Hammerspoon modules, both driven by skhd keybinds:
--
-- windowSwitcher - visual keyboard window switcher, scoped to the current Space.
-- Trigger: skhd sends `alt-tab` / `cmd-tab` -> `hs -c 'windowSwitcher.show()'`
-- (see skhdrc). Once the overlay is open (release the modifier key):
--   tab / right / j       -> next window
--   shift-tab / left / k  -> previous window
--   m                     -> switch selector between regular/minimized lists
--   return                -> focus selected window (unminimizing if needed)
--   escape                -> cancel
-- Implementation is split across window_switcher/:
--   sources.lua    - which windows are candidates (current-Space query)
--   overlay.lua    - how the switcher looks (canvas drawing)
--   controller.lua - state + keybindings + the show/hide/toggle API below
--
-- windowMover - moves the focused window to another Space. Trigger: skhd
-- sends `ctrl+cmd-1..9` -> `hs -c 'windowMover.moveToSpace(N)'` (see window_mover/).

-- Required so `hs -c '...'` (what skhd calls above) has a message port to
-- connect to. Also install the CLI once, from the Hammerspoon Console:
--   hs.ipc.cliInstall()
require("hs.ipc")

-- Reload this config automatically on save, instead of needing a manual
-- Hammerspoon reload every time a file under here changes.
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

local windowSwitcher = require("window_switcher.controller")
local windowMover = require("window_mover")

-- Exposed as globals so `hs -c '...'` (invoked from skhd) can reach them.
_G.windowSwitcher = windowSwitcher
_G.windowMover = windowMover

return windowSwitcher
