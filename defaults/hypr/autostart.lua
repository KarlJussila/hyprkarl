-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    -- Hyprland starts with any installed Hyprcursor theme when the theme's
    -- cursor has no Hyprcursor version, so set the theme's cursor explicitly.
    hl.exec_cmd([[hyprctl setcursor "$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/hyprkarl/current/theme/cursor.theme")" "$XCURSOR_SIZE"]])
    hl.exec_cmd("systemctl --user start hypridle.service")
    hl.exec_cmd([[hk-shell start; hk-hook-run login || notify-send "Hyprkarl login hook failed" "Check the hook output in the Hyprland log."]])
    hl.exec_cmd("hk-wallpaper init || hk-wallpaper cycle")

    -- Slow app launch fix -- set systemd vars
    hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)
