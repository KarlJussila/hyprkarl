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
	impala \
	bluetui \
	wiremix \
	yazi \
	ttf-jetbrains-mono-nerd

paru -S --needed --noconfirm \
	xdg-terminal-exec \
	vscodium \
	hyprshutdown

# Remove packages
sudo pacman -Rns --noconfirm \
	wofi \
	dolphin
 
# Create directories
mkdir -p $HOME/.local/share/hyprkarl/bin
mkdir -p $HOME/.config/waybar
mkdir -p $HOME/.config/uwsm
mkdir -p $HOME/.config/bindings

# Move/edit system files
sudo cp system/iwd-main.conf /etc/iwd/main.conf

# Enable/disable services
sudo systemctl enable --now iwd
sudo systemctl disable --now NetworkManager
sudo systemctl disable --now wpa_supplicant
