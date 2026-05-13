#!/bin/bash

# This script installs packages for the hyprkarl setup.
# NOTE: It also removes some packages that are replaced with alternatives.
# Use yay consistently for AUR-backed installs and queries.

# Install packages
sudo pacman -S --needed --noconfirm \
  waybar \
  hyprpaper \
  hyprlock \
  hypridle \
  hyprsunset \
  mako \
  hyprpolkitagent \
  brightnessctl \
  curl \
  ffmpeg \
  fzf \
  imagemagick \
  jq \
  nautilus \
  playerctl \
  rofi \
  hyprshot \
  hyprpicker \
  satty \
  stow \
  neovim \
  vscodium \
  bluetui \
  wiremix \
  yazi \
  ttf-jetbrains-mono-nerd \
  ttf-iosevka-nerd \
  xdg-desktop-portal-gtk \
  mpv \
  imv \
  flatpak \
  gum \
  localsend \
  yay-bin \
  foot \
  gpu-screen-recorder \
  perl-image-exiftool \
  v4l-utils \
  wl-clipboard \
  xkbcommon-tools \
  ghostty \
  kvantum \
  kvantum-qt5 \
  qt6ct \
  qt5ct \
  7zip \
  resvg \
  rofi-calc \
  aylurs-gtk-shell \
  dart-sass

yay -S --needed --noconfirm \
  xdg-terminal-exec \
  hyprshutdown \
  wifitui-bin \
  yaru-icon-theme \
  dragon-drop \
  xdg-desktop-portal-termfilechooser-hunkyburrito-git \
  libastal-hyprland-git \
  libastal-battery-git \
  libastal-powerprofiles-git \
  libastal-network-git \
  libastal-bluetooth-git \
  libastal-tray-git \
  libastal-wireplumber-git

# Remove packages
sudo pacman -Rns --noconfirm \
  wofi \
  dolphin
