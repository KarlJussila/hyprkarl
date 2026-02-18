#!/bin/bash

# This script installs packages for the hyprkarl setup.
# NOTE: It also removes some packages that are replaced with alternatives

# Install packages
sudo pacman -S --needed --noconfirm \
	waybar \
	swaybg \
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
	ttf-jetbrains-mono-nerd

paru -S --needed --noconfirm \
	xdg-terminal-exec \
	hyprshutdown \
	wifitui-bin

# Remove packages
sudo pacman -Rns --noconfirm \
	wofi \
	dolphin