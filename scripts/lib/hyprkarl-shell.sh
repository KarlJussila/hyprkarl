HYPRKARL_PATH="${HYPRKARL_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
HYPRKARL_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPRKARL_ROFI_CUSTOM_THEME="$HYPRKARL_CONFIG_HOME/rofi/custom-menu.rasi"
HYPRKARL_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/hyprkarl"

export HYPRKARL_PATH

hyprkarl_parse_back_args() {
  HYPRKARL_BACK_ARGS=()

  if [[ "${1:-}" == "--back" ]]; then
    shift
    HYPRKARL_BACK_ARGS=("$@")
  fi
}

hyprkarl_build_self_command() {
  local command_name
  command_name=$(basename "$1")

  HYPRKARL_SELF_COMMAND=("$command_name")
  if ((${#HYPRKARL_BACK_ARGS[@]})); then
    HYPRKARL_SELF_COMMAND+=(--back "${HYPRKARL_BACK_ARGS[@]}")
  fi
}

hyprkarl_run_back() {
  (("$#" > 0)) || return 0
  "$@"
}

hyprkarl_open_terminal() {
  xdg-terminal-exec --app-id=org.hyprkarl.terminal "$@"
}

hyprkarl_capture_terminal_output() {
  local output_file
  output_file=$(mktemp) || return 1

  if ! hyprkarl_open_terminal -e bash -lc 'output_file=$1; shift; "$@" >"$output_file"' bash "$output_file" "$@"; then
    rm -f "$output_file"
    return 1
  fi

  cat "$output_file"
  rm -f "$output_file"
}

hyprkarl_find_battery() {
  local battery_path

  for battery_path in /sys/class/power_supply/BAT*; do
    if [[ -d "$battery_path" ]]; then
      basename "$battery_path"
      return 0
    fi
  done

  return 1
}

hyprkarl_find_display_backlight() {
  local backlight_path

  for backlight_path in \
    /sys/class/backlight/amdgpu_bl* \
    /sys/class/backlight/intel_backlight \
    /sys/class/backlight/acpi_video* \
    /sys/class/backlight/*; do
    if [[ -d "$backlight_path" ]]; then
      basename "$backlight_path"
      return 0
    fi
  done

  return 1
}

hyprkarl_find_keyboard_backlight() {
  local backlight_path

  for backlight_path in /sys/class/leds/*kbd_backlight*; do
    if [[ -d "$backlight_path" ]]; then
      basename "$backlight_path"
      return 0
    fi
  done

  return 1
}
