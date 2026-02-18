# hyprkarl
Work in progress configuration files for CachyOS + hyprland

## WARNINGS
- This is largely untested. Use at your own risk.
- Read warnings for other sections.

## Requirements
- Base CachyOS (hyprland) install

## Setup
### WARNINGS
- This removes some default packages in favor of others. Please review the setup script before running it if you are worried about that.

### Process
- Clone into `~/.local/share/`
    ```
    git clone --depth=1 https://github.com/KarlJussila/hyprkarl.git
    ```
- cd into the `~/.local/share/hyprkarl` directory
- Set up packages with `setup-packages.sh`
    ```
    chmod +x setup-packages.sh
    ./setup-packages.sh
    ```

## Dotfile Installation (manual)
- Use uwsm configs to enable the hyprkarl commands (essential for operation of most configs)
- For now, move configs manually into their places in `~/.config`
- The config/hyprkarl directory just has theming files at the moment; I think only really the waybar config is 100% necessary for defining colors referenced in the primary configs.

## Dotfile Installation (automated)
### WARNINGS
- This will replace existing dotfiles. Back them up if you want to keep them.

### Process
- Set up dotfiles with `setup-dotfiles.sh`
    ```
    chmod +x setup-dotfiles.sh
    ./setup-dotfiles.sh
    ```