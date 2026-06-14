local terminal = "uwsm-app -- xdg-terminal-exec"
local terminalAlt = "uwsm-app -- foot"
local browser = "hk-launch-browser"

hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(terminal .. ' --dir="$(hk-terminal-cwd)"'), { description = "Terminal" })
hl.bind("SUPER + SHIFT + RETURN", hl.dsp.exec_cmd(terminalAlt), { description = "Alternative terminal" })
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd(terminal .. ' --app-id=org.hyprkarl.terminal yazi "$(hk-terminal-cwd)"'), { description = "File manager" })
hl.bind("SUPER + ALT + F", hl.dsp.exec_cmd("uwsm-app -- nautilus --new-window"), { description = "Alternative file manager" })
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd(browser), { description = "Browser" })
hl.bind("SUPER + SHIFT + ALT + B", hl.dsp.exec_cmd(browser .. " --private"), { description = "Browser (private)" })
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("hk-launch-editor"), { description = "Editor" })

hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("hk-launch-tui hk-dictionary"), { description = "Dictionary" })
hl.bind("SUPER + SHIFT + I", hl.dsp.exec_cmd("hk-menu-icons"), { description = "Icon picker" })
