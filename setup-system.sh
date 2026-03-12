#!/bin/bash

# Set up gnome/gtk themes
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface icon-theme "Yaru-purple"

sudo gtk-update-icon-cache /usr/share/icons/Yaru

# Replace any conflicting [Autologin] section from /etc/sddm.conf
sudo tee /etc/sddm.conf <<EOF
[Autologin]gh
User=$USER
Session=hyprland-uwsm

[Theme]
Current=breeze
EOF

# Set up autologin for sddm
sudo mkdir -p /etc/sddm.conf.d

if [ ! -f /etc/sddm.conf.d/autologin.conf ]; then
  cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf
[Autologin]
User=$USER
Session=hyprland-uwsm

[Theme]
Current=breeze
EOF
fi

# Give the user 10 instead of 3 tries to enter their password before lockout
echo "Defaults passwd_tries=10" | sudo tee /etc/sudoers.d/passwd-tries
sudo chmod 440 /etc/sudoers.d/passwd-tries

# Set for hyprlock too
sudo sed -i 's/^# *deny = .*/deny = 10/' /etc/security/faillock.conf

# Allow localsend port
sudo ufw allow 53317/tcp
sudo ufw allow 53317/udp

# Enable ghostty service
systemctl enable --user app-com.mitchellh.ghostty.service