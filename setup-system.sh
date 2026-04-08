#!/bin/bash

# Set up gnome/gtk themes
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface icon-theme "Yaru-purple"

sudo gtk-update-icon-cache /usr/share/icons/Yaru

# Set up SDDM autologin
sed "s/{{USER}}/$USER/g" "$HYPRKARL_PATH/templates/setup/sddm.conf" | sudo tee /etc/sddm.conf

# Disable logind lid switch handling
sudo mkdir -p /etc/systemd/logind.conf.d
sudo cp "$HYPRKARL_PATH/templates/setup/logind-lid.conf" /etc/systemd/logind.conf.d/lid.conf

# Give the user 10 instead of 3 tries to enter their password before lockout
echo "Defaults passwd_tries=10" | sudo tee /etc/sudoers.d/passwd-tries
sudo chmod 440 /etc/sudoers.d/passwd-tries

# Set for hyprlock too
sudo sed -i 's/^# *deny = .*/deny = 10/' /etc/security/faillock.conf

# Allow localsend port
sudo ufw allow 53317/tcp
sudo ufw allow 53317/udp