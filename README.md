# hyprkarl
Work in progress configuration files for CachyOS + Hyprland.

> **Warning:** This is largely untested. Use at your own risk.

## Requirements
- Base CachyOS (Hyprland) install

## Setup

Clone into `~/.local/share/` and cd into the directory:
```bash
git clone --depth=1 https://github.com/KarlJussila/hyprkarl.git
cd ~/.local/share/hyprkarl
```

Then choose one of the following:

---

### Fully Automated Setup

> **Warning:** All warnings in this README--including those in the manual setup--apply. Read them before proceeding.
```bash
chmod +x setup-*.sh
./setup-all.sh
```

---

### (More) Manual Setup

#### 1. Packages

> **Warning:** This removes some default packages in favor of others. Review `setup-packages.sh` before running it.
```bash
chmod +x setup-packages.sh
./setup-packages.sh
```

#### 2. Dotfiles

> **Warning:** This will replace existing dotfiles. Back them up if you want to keep them.

The directory structure under `config/` mirrors `~/.config`. You can either copy files manually, or run:
```bash
chmod +x setup-dotfiles.sh
./setup-dotfiles.sh
```

#### 3. System Tweaks

Configures dark mode, SDDM autologin, and increased password retries.

> **Warning:** This will bypass the SDDM login screen.
```bash
chmod +x setup-system.sh
./setup-system.sh
```