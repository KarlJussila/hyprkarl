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
 
# Create directories
mkdir -p $HOME/.local/share/hyprkarl/bin
mkdir -p $HOME/.config/waybar
mkdir -p $HOME/.config/uwsm
mkdir -p $HOME/.config/bindings