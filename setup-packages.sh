#!/bin/bash

# This script installs packages for the hyprkarl setup.
# NOTE: It also removes some packages that are replaced with alternatives

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
  nautilus \
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
  ghostty \
  kvantum \
  kvantum-qt5 \
  qt6ct \
  qt5ct \
  7zip \
  resvg

paru -S --needed --noconfirm \
  xdg-terminal-exec \
  hyprshutdown \
  wifitui-bin \
  yaru-icon-theme \
  dragon-drop \
  xdg-desktop-portal-termfilechooser-hunkyburrito-git

# Remove packages
sudo pacman -Rns --noconfirm \
  wofi \
  dolphin
