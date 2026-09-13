hl.bind("SUPER + W", hl.dsp.exec_cmd("gtk-launch com.rtosta.zapzap"))
hl.bind("CTRL+ SPACE", hl.dsp.exec_cmd("caelestia wallpaper -r"))


-- Window resize
hl.bind("CTRL + ALT + LEFT", hl.dsp.window.resize({
    x = -50,
    y = 0,
    relative = true
}))

hl.bind("CTRL + ALT + RIGHT", hl.dsp.window.resize({
    x = 50,
    y = 0,
    relative = true
}))

hl.bind("CTRL + ALT + UP", hl.dsp.window.resize({
    x = 0,
    y = -50,
    relative = true
}))

hl.bind("CTRL + ALT + DOWN", hl.dsp.window.resize({
    x = 0,
    y = 50,
    relative = true
}))