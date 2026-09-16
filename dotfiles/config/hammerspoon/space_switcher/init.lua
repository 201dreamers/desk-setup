-- Jumps to the last Space on the focused display, from wherever you are -
-- including a fullscreen app's Space, which always sits at the end of the
-- Space list. One Space-switch animation, never two.
--
-- Why not `yabai -m space --focus last`: that goes through yabai's
-- scripting addition, which needs SIP partially disabled - not the case on
-- this machine, so the command silently no-ops (exits 0, focus never
-- moves). Why not hs.spaces.gotoSpace: it drives Mission Control's
-- accessibility tree through the Dock, which fails here ("no display with
-- specified id found").
--
-- What does work, one hop each:
--   yabai -m window --focus <id>   macOS follows the window to its Space,
--                                  fullscreen Spaces included. Plain window
--                                  focus needs no scripting addition.
--   Control+1..9                   "Switch to Desktop N" - for an empty
--                                  Space, where there's no window to focus.
--
-- Fullscreen Spaces always hold exactly one window, so they always take the
-- first path. Numbered Desktops prefer Control+N, which keeps whatever
-- window you last used there focused instead of forcing focus onto another.
--
-- Trigger: skhd sends `ctrl+cmd-l` -> `hs -c 'spaceSwitcher.focusLast()'`

local M = {}

local YABAI = "/opt/homebrew/bin/yabai"
-- Native "Switch to Desktop N" shortcuts only go up to Control+9.
local MAX_NATIVE_DESKTOP = 9

local function query(args)
    local output, ok = hs.execute(YABAI .. " -m query " .. args)
    if not ok or not output or output == "" then
        return nil
    end
    return hs.json.decode(output)
end

-- Position of a Space among the numbered Desktops on its display - which is
-- also the N in the Control+N shortcut that switches to it. Fullscreen
-- Spaces have no number, so they don't count toward it.
local function desktopNumber(spaces, target)
    local number = 0
    for _, space in ipairs(spaces) do
        if not space["is-native-fullscreen"] then
            number = number + 1
        end
        if space.id == target.id then
            return number
        end
    end
    return nil
end

function M.focusLast()
    local spaces = query("--spaces")
    if not spaces then
        hs.alert.show("yabai query failed")
        return
    end

    -- Space indices run across all displays, so keep only the focused one's
    -- Spaces before taking "the last". The focused Space names that display,
    -- which saves a second `query --displays` round trip (~20ms).
    local display = nil
    for _, space in ipairs(spaces) do
        if space["has-focus"] then
            display = space.display
            break
        end
    end

    local onDisplay = {}
    for _, space in ipairs(spaces) do
        if not display or space.display == display then
            onDisplay[#onDisplay + 1] = space
        end
    end

    local target = onDisplay[#onDisplay]
    if not target or target["has-focus"] then
        return
    end

    -- A fullscreen Space is only reachable this way; an occupied Desktop
    -- past Control+9 also has no shortcut left to use.
    local number = desktopNumber(onDisplay, target)
    -- first-window is 0 on a fullscreen Space (yabai doesn't manage those
    -- windows), so fall back to the Space's raw window list.
    local window = target["first-window"]
    if not window or window == 0 then
        window = (target.windows or {})[1]
    end
    if window and window ~= 0 and (target["is-native-fullscreen"] or not number or number > MAX_NATIVE_DESKTOP) then
        hs.execute(YABAI .. " -m window --focus " .. window)
        return
    end

    if not number or number > MAX_NATIVE_DESKTOP then
        hs.alert.show("Last Space is past Control+" .. MAX_NATIVE_DESKTOP .. " and is empty")
        return
    end
    hs.eventtap.keyStroke({ "ctrl" }, tostring(number), 0)
end

return M
