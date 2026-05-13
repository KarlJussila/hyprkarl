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
