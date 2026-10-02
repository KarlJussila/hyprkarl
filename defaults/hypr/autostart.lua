-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("hk-theme cursor")
    hl.exec_cmd("systemctl --user start hypridle.service")
    hl.exec_cmd([[hk-shell start; hk-hook-run post-boot || notify-send "Hyprkarl post-boot hook failed" "Check the hook output in the Hyprland log."]])
    hl.exec_cmd("uwsm app -- hyprpaper")
    hl.exec_cmd("hk-wallpaper init || hk-wallpaper cycle")

    -- Slow app launch fix -- set systemd vars
    hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)
