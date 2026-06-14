-- System controls: menus, notifications, hardware panels, screenshots, power.

-- Menus
hl.bind("SUPER + ALT + SPACE", hl.dsp.exec_cmd("hk-menu || pkill rofi"), { description = "Main menu" })
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("hk-menu-launcher || pkill rofi"), { description = "Launch apps" })
hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("hk-menu-power || pkill rofi"), { description = "Power menu" })
hl.bind("SUPER + K", hl.dsp.exec_cmd("hk-menu-keybindings || pkill rofi"), { description = "View keybinds" })
hl.bind("SUPER + CTRL + SPACE", hl.dsp.exec_cmd("hk-menu-ags || pkill rofi"), { description = "AGS bar menu" })
hl.bind("SUPER + CTRL + C", hl.dsp.exec_cmd("hk-menu-calculator || pkill rofi"), { description = "Calculator" })

-- Notifications
hl.bind("SUPER + COMMA", hl.dsp.exec_cmd("makoctl dismiss"), { description = "Dismiss last notification" })
hl.bind("SUPER + SHIFT + COMMA", hl.dsp.exec_cmd("makoctl dismiss --all"), { description = "Dismiss all notifications" })
hl.bind("SUPER + CTRL + COMMA", hl.dsp.exec_cmd([[makoctl mode -t do-not-disturb && makoctl mode | grep -q 'do-not-disturb' && notify-send "Silenced notifications" || notify-send "Enabled notifications"]]), { description = "Toggle silencing notifications" })
hl.bind("SUPER + ALT + COMMA", hl.dsp.exec_cmd("makoctl invoke"), { description = "Invoke last notification" })
hl.bind("SUPER + SHIFT + ALT + COMMA", hl.dsp.exec_cmd("makoctl restore"), { description = "Restore last notification" })

-- Toggle nightlight
hl.bind("SUPER + CTRL + N", hl.dsp.exec_cmd("hk-nightlight"), { description = "Toggle nightlight" })

-- Control panels
hl.bind("SUPER + CTRL + A", hl.dsp.exec_cmd("hk-launch-audio"), { description = "Audio controls" })
hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd("hk-launch-bluetooth"), { description = "Bluetooth controls" })
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd("hk-launch-wifi"), { description = "Wifi controls" })
hl.bind("SUPER + CTRL + T", hl.dsp.exec_cmd("hk-launch-tui btop"), { description = "Activity" })

-- Screenshots
hl.bind("SUPER + PRINT", hl.dsp.exec_cmd("hyprshot -m window"), { description = "Screenshot window" })
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"), { locked = true, description = "Screenshot display" })
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"), { locked = true, description = "Screenshot region" })

-- Suspend on lid close
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hk-suspend"), { description = "Suspend on lid close" })

-- Open power menu with the power button
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("hk-menu-power"), { description = "Power menu (power button)" })
