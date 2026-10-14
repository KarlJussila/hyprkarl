-- Laptop multimedia keys for volume and LCD brightness (with OSD)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("hk-volume raise"), { repeating = true, locked = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("hk-volume lower"), { repeating = true, locked = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("hk-volume toggle"), { repeating = true, locked = true, description = "Mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("hk-mic toggle"), { repeating = true, locked = true, description = "Mute microphone" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("hk-brightness-display +5%"), { repeating = true, locked = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("hk-brightness-display 5%-"), { repeating = true, locked = true, description = "Brightness down" })
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("hk-brightness-keyboard up"), { repeating = true, locked = true, description = "Keyboard brightness up" })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("hk-brightness-keyboard down"), { repeating = true, locked = true, description = "Keyboard brightness down" })

-- Playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("hk-playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("hk-playerctl play-pause"), { locked = true, description = "Pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("hk-playerctl play-pause"), { locked = true, description = "Play" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("hk-playerctl previous"), { locked = true, description = "Previous track" })

-- Switch audio output with Super + Mute
hl.bind("SUPER + XF86AudioMute", hl.dsp.exec_cmd("hk-audio-switch"), { locked = true, description = "Switch audio output" })
