-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hypridle.service")
    hl.exec_cmd("uwsm-app -- mako")
    hl.exec_cmd("uwsm app -- systemctl --user start hyprpolkitagent")
    hl.exec_cmd("uwsm app -- ags run")
    hl.exec_cmd("uwsm app -- hyprpaper")
    hl.exec_cmd("hk-wallpaper init || hk-wallpaper cycle")

    -- Slow app launch fix -- set systemd vars
    hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)
