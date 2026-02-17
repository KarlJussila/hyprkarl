Work in progress configuration files for CachyOS + hyprland. Clone into ~/.local/share/hyprkarl.

Install/uninstall necessary packages with setup.sh. Use uwsm configs to enable the hyprkarl commands (essential for operation of most configs). For now, move configs manually into their places in .config. The hyprkarl config directory just has theming files at the moment; I think only really the waybar config is 100% necessary for defining colors referenced in the primary configs. I plan to make a script for moving the files automatically once I have the configs settled.

Note: if you don't want to use impala for WiFi, don't run the whole setup script. It will disable other network managers and move a config for iwd into /etc/iwd/main.conf. This will probably turn off your WiFi. Open Impala, and you should be able to reconnect.
