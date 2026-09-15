-- ============================================================
-- Custom Keybinds
-- ============================================================


-- ------------------------------------------------------------
-- Applications
-- ------------------------------------------------------------

-- Open WhatsApp
hl.bind("SUPER + W", hl.dsp.exec_cmd("gtk-launch com.rtosta.zapzap"))


-- ------------------------------------------------------------
-- Wallpaper
-- ------------------------------------------------------------

-- Random wallpaper
hl.bind("CTRL + W", hl.dsp.exec_cmd("caelestia wallpaper -r"))


-- ------------------------------------------------------------
-- Persistent Mode
-- ------------------------------------------------------------

-- Toggle Caelestia persistent mode
-- CTRL + B: ON <-> OFF
hl.bind(
    "CTRL + B",
    hl.dsp.exec_cmd("bash ~/.config/caelestia/scripts/toggle-persistent.sh")
)


-- ------------------------------------------------------------
-- Window Resize
-- ------------------------------------------------------------

-- Resize window to the left
hl.bind(
    "CTRL + ALT + LEFT",
    hl.dsp.window.resize({
        x = -50,
        y = 0,
        relative = true
    })
)

-- Resize window to the right
hl.bind(
    "CTRL + ALT + RIGHT",
    hl.dsp.window.resize({
        x = 50,
        y = 0,
        relative = true
    })
)

-- Resize window upward
hl.bind(
    "CTRL + ALT + UP",
    hl.dsp.window.resize({
        x = 0,
        y = -50,
        relative = true
    })
)

-- Resize window downward
hl.bind(
    "CTRL + ALT + DOWN",
    hl.dsp.window.resize({
        x = 0,
        y = 50,
        relative = true
    })
)