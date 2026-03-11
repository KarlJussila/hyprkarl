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
	swayosd \
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
	ghostty

paru -S --needed --noconfirm \
	xdg-terminal-exec \
	hyprshutdown \
	wifitui-bin \
	yaru-icon-theme \
	dragon-drop

# Remove packages
sudo pacman -Rns --noconfirm \
	wofi \
	dolphin