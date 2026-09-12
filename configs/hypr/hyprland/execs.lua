local vars = require("variables")
local fn   = require("utils.functions")

-- ============================================================
-- Hyprland Startup Hook
-- Runs once when Hyprland starts; sets up daemons, cursors,
-- clipboard, location services, and the shell.
-- ============================================================
hl.on("hyprland.start", function()
    -- Keyring and auth
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Auto delete trash older than 30 days
    hl.exec_cmd("trash-empty 30")

    -- Cursor theme and size
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. vars.cursorTheme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. vars.cursorSize)

    -- Location provider and night light
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    hl.exec_cmd("sleep 1 && gammastep")

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- Start shell
    hl.exec_cmd("caelestia shell -d")

    -- Start workspace overview
    hl.exec_cmd("qs-overview start")
end)

-- ============================================================
-- Window Resizer Rules
-- Applies float/center (or custom) rules to specific windows
-- based on their class/title, e.g. Bitwarden popups and PiP.
-- ============================================================
local function apply_resizer_rules(win)
    -- Default action: float and center the window
    local float_center = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }

    -- Picture-in-picture specific move actions
    local pip_actions = fn.move_actions(win) or {}

    -- --- Bitwarden ---
    fn.resizer(win, "Bitwarden", 20, 54, float_center, true, "class")                                       -- Native app
    fn.resizer(win, "^Extension: %(Bitwarden Password Manager%) %- Bitwarden", 20, 54, float_center, false) -- Firefox extension
    fn.resizer(win, "nngceckbapebfimnlniiiahkandclblb", 20, 54, float_center, true, "class")                -- Chromium extension

    -- --- Picture in Picture ---
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip_actions, false)
end

-- Register listeners so rules apply on title change and window open
hl.on("window.title", apply_resizer_rules)
hl.on("window.open", apply_resizer_rules)